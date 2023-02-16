import os
import xml.etree.ElementTree as ET

from hashlib import sha1
from subprocess import Popen, PIPE

from pycompat import httplib

from dbusproxies import NetworkManagerProxy
from client import NAME, VERSION
from netdev import get_real_hwaddress


class PaladinCloudReporter(object):

    OPTIONS = ['enable', 'useSSL', 'server', 'port', 'service', 'reportUserIdentity', 'reportIP']
    ORGANIZATION_DATA = ['name', 'UID']

    REQUEST_TYPE_REPORT = 4
    REQUEST_TYPE_CONFIGURATION = 7

    ERROR_CONNECTION_TIMED_OUT = 5
    ERROR_CONNECTION_FAILED_OTHER = 13

    def __init__(self, config, devicecfg, organization=None):

        self.adapters = []
        self.deviceid = None
        self.devicedata = {}
        self.devicecfgdata = {}
        self.identity = None
        self.ipaddress = None

        self.devicecfgdata['id'] = devicecfg.get('id')

        try:
            self.devicecfgdata['profileId'] = devicecfg.find('profileUUID').text
        except AttributeError:
            pass

        try:
            self.devicecfgdata['name'] = devicecfg.find('name').text
        except AttributeError:
            pass

        self.organizationdata = dict((k, d.text) for k, d in filter(lambda e: e[1] != None, [(k, organization.find(k)) for k in self.ORGANIZATION_DATA])) if organization != None else {}

        try:
            self.config = dict((k, config.find(k).text) for k in self.OPTIONS)
        except AttributeError:
            print('No or invalid cloud reporting configuration')
            self.config = {'enable': 'false'}

        self.enabled = self.config['enable'] == 'true'
        self.senddeviceinfo = True

    def config_param(self, name, default=None):
        if name in self.config:
            return self.config[name]
        return default

    def config_enabled(self, name='enable'):
        return self.config_param(name) == 'true'

    def report_ip(self):
        return self.config_enabled('reportIP')

    def _collect_from_uname(self, uname_opt):
        p = Popen('uname -' + uname_opt, stdout=PIPE, shell=True)
        return p.communicate()[0].decode('utf-8').split('\n')[0]

    def _collect_hostname(self):
        p = Popen('hostname -s', stdout=PIPE, shell=True)
        return p.communicate()[0].decode('utf-8').split('\n')[0]

    def collect_from_uname(self, key, uname_opt):
        try:
            self.devicedata[key] = self._collect_from_uname(uname_opt)
        except:
            pass

    def gendeviceid(self):
        # Try to obtain unprivileged system specific data:
        try:
            with open('/sys/class/dmi/id/modalias', 'r') as f:
                hashdata = f.read().replace('\n', '').encode('utf-8')
        except:
            hashdata = b''

        # Add DBus Machine ID
        try:
            try:
                with open('/var/lib/dbus/machine-id', 'r') as f:
                    hashdata += f.read().replace('\n', '').encode('utf-8')
            except (IOError, OSError):
                with open('/etc/machine-id', 'r') as f:
                    hashdata += f.read().replace('\n', '').encode('utf-8')
        except:
            if len(self.adapters) > 0:
                hashdata += str(self.adapters[0][1]).encode('utf-8')
            else:
                hashdata += os.urandom(6)

        self.deviceid = sha1(hashdata).hexdigest()

    def collect_attributes(self):
        self.collect_from_uname('buildModel', 'o')
        self.collect_from_uname('buildVersion', 'r')
        self.collect_from_uname('OSArchitecture', 'm')

        try:
            self.devicedata['OSArchitecture'] = '32-bit' if not '64' in self.devicedata['OSArchitecture'] else '64-bit'
        except KeyError:
            pass

        try:
            nm = NetworkManagerProxy()
            for device in nm.get_wireless_devices():
                try:
                    name = nm.dev_get_name(device)
                    mac = nm.dev_get_macaddress(device)
                    try:
                        mac = get_real_hwaddress(name)
                    except:
                        pass
                    self.adapters += [ (name, mac) ]
                except:
                    pass
        except:
            pass

        self.gendeviceid()

    def set_identity(self, identity):
        self.identity = identity

    def set_ipaddress(self, ipaddress):
        self.ipaddress = ipaddress

    def create_xml(self, reporttype, deviceinfo=True, deviceconfig=True, error=None, ipaddress=None, identity=None):
        xml = ET.Element('paladinRequest')
        xml.set('xmlns', 'http://schemas.securew2.com/paladinRequest')
        xml.set('type', str(reporttype))

        organization = ET.SubElement(xml, 'organization')
        for k in self.organizationdata:
            e = ET.SubElement(organization, k)
            e.text = self.organizationdata[k]

        device = ET.SubElement(xml, 'device')

        if self.deviceid:
            device.set('id', self.deviceid)

        if deviceinfo:
            devicedata = {'applicationVersionName': NAME, 'applicationVersion': VERSION}
            for k in self.devicedata: devicedata[k] = self.devicedata[k]

            for k in devicedata:
                e = ET.SubElement(device, k)
                e.text = devicedata[k]

            adapters = ET.SubElement(device, 'adapters')

            for a in self.adapters:
                adapter = ET.SubElement(adapters, 'adapter')
                e = ET.SubElement(adapter, 'description')
                e.text = a[0]
                e = ET.SubElement(adapter, 'MACAddress')
                e.text = a[1]

        if deviceconfig:
            devicecfgdata = {'errorCode': str(error[0])} if error is not None else {}

            for k in filter(lambda k: k in [ 'id', 'name' ], self.devicecfgdata):
                devicecfgdata[k] = self.devicecfgdata[k]

            if error is not None and error[1]:
                devicecfgdata['errorMessage'] = error[1]

            if ipaddress and self.report_ip():
                devicecfgdata['IPAddress'] = ipaddress

            devicecfg = ET.SubElement(xml, 'deviceConfiguration', attrib={'id': self.devicecfgdata['id']})
            for k in devicecfgdata:
                e = ET.SubElement(devicecfg, k)
                e.text = devicecfgdata[k]

            if identity and self.config_enabled('reportUserIdentity'):
                user = ET.SubElement(devicecfg, 'user')
                userid = ET.SubElement(user, 'identity')
                userid.text = identity

            if 'profileId' in self.devicecfgdata:
                ET.SubElement(xml, 'profile', attrib={'uuid': self.devicecfgdata['profileId']})

        return ET.tostring(xml)

    def connect(self):
        connclass = httplib.HTTPSConnection if self.config_enabled('useSSL') else httplib.HTTPConnection
        return connclass(self.config['server'], int(self.config_param('port', 443 if self.config_enabled('useSSL') else 80)))

    def send_report(self, data):
        try:
            conn = self.connect()
            conn.request('POST', '/' + self.config['service'], data, {'Content-Type': 'application/xml'})
            return conn.getresponse().status
        except:
            pass

    def report(self):
        if not self.enabled:
            return None

        if not self.deviceid:
            self.collect_attributes()

        xml = self.create_xml(self.REQUEST_TYPE_REPORT)
        return self.send_report(xml)

    def sendconfiguration(self, errorcode, errormsg=None, ipaddress=None, identity=None):
        if not self.enabled:
            return None

        if not identity and self.identity:
            identity = self.identity

        if not ipaddress and self.ipaddress:
            ipaddress = self.ipaddress

        xml = self.create_xml(self.REQUEST_TYPE_CONFIGURATION, deviceinfo=self.senddeviceinfo, error=(errorcode, errormsg), ipaddress=ipaddress, identity=identity)
        return self.send_report(xml)

    def nextgen_device_attributes(self):
        if not self.deviceid:
            self.collect_attributes()

        yield 'clientId', self.deviceid
        yield 'applicationFriendlyName', NAME
        yield 'applicationVersion', VERSION
        yield 'buildModel', 'PC'

        if 'buildModel' in self.devicedata:
            yield 'operatingSystem', self.devicedata['buildModel']

        if 'buildVersion' in self.devicedata:
            yield 'osVersion', self.devicedata['buildVersion']
            yield 'osVersionFriendlyName', self.devicedata['buildVersion']

        try:
            yield 'osBuild', filter(lambda s: s[:1] == '#', self._collect_from_uname('v').split(' '))[0][1:]
        except:
            pass

        if 'OSArchitecture' in self.devicedata:
            yield 'osArchitecture', self.devicedata['OSArchitecture']

        if self.report_ip():
            try:
                yield 'computerIdentity', self._collect_hostname()
            except:
                pass
            if self.ipaddress != None:
                yield 'ipAddress', self.ipaddress

        yield 'adapters', { 'wireless': [ { 'name': v[0], 'macAddress': v[1] } for v in self.adapters ] }

    def nextgen_configinfo(self):
        if 'profileId' in self.devicecfgdata:
            yield 'profileId', self.devicecfgdata['profileId']
        elif 'id' in self.devicecfgdata:
            try:
                yield 'deviceConfigId', int(self.devicecfgdata['id'])
            except ValueError:
                pass

        if 'name' in self.devicecfgdata:
            yield 'deviceConfigName', self.devicecfgdata['name']

        if 'UID' in self.organizationdata:
            yield 'organizationId', str(self.organizationdata['UID'])


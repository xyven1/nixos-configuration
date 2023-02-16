import dbus
import uuid
from time import sleep
from dbus.exceptions import DBusException

from pycompat import time, _long

from detect import wpa_supplicant_version

def dbus_path(path):
    if path != None and len(path) > 0:
        if path[0] == '/':
            path = 'file://' + path
        return dbus.ByteArray((path + "\0").encode('utf-8'))

class InvalidDBusObjectPathException(Exception):
    pass

class NoIp4ConfigAvailable(Exception):
    pass

class NoIp4ConfigAddressDataAvailable(Exception):
    pass

class GnomeShellScriptExecutionException(Exception):
    pass

class DBusObjectProxy(object):
    BUS = None
    SERVICE = None

    PATH = None
    IFACE = None

    def __init__(self):
        self.bus = self.BUS()
        self.reopen()

    def reopen(self):
        self.main_iface = self.get_object_iface(self.PATH, self.IFACE)

    def assert_object_path(self, obj_path, allow_root_object=False):
        if obj_path == None or obj_path == '' or (allow_root_object == False and obj_path == '/'):
            raise InvalidDBusObjectPathException(str(obj_path))
        return obj_path

    def get_object_proxy(self, obj_path):
        return self.bus.get_object(self.SERVICE, self.assert_object_path(obj_path))

    def get_object_iface(self, obj, iface):
        if type(obj) != dbus.proxies.ProxyObject:
            obj = self.get_object_proxy(obj)
        return dbus.Interface(obj, iface)

    def get_object_property(self, obj, property_name, property_iface_name):
        return self.get_object_iface(obj, dbus.PROPERTIES_IFACE).Get(property_iface_name, property_name)

    def set_object_property(self, obj, property_name, property_iface_name, value):
        return self.get_object_iface(obj, dbus.PROPERTIES_IFACE).Set(property_iface_name, property_name, value)

    @staticmethod
    def decode_bytearray(ba):
        return ''.join([chr(c) for c in ba ])


class SecretsServiceProxy(DBusObjectProxy):
    BUS = dbus.SessionBus
    SERVICE = 'org.freedesktop.secrets'

    PATH    = '/org/freedesktop/secrets'
    IFACE   = 'org.freedesktop.Secret.Service'

    SESSION_IFACE               = 'org.freedesktop.Secret.Session'

    DEFAULT_COLLECTION_PATH     = '/org/freedesktop/secrets/collection/login'
    COLLECTION_IFACE            = 'org.freedesktop.Secret.Collection'
    COLLECTION_LABEL_PROPERTY   = 'org.freedesktop.Secret.Collection.Label'

    ITEM_IFACE                  = 'org.freedesktop.Secret.Item'
    ITEM_LABEL_PROPERTY         = 'org.freedesktop.Secret.Item.Label'
    ITEM_ATTRIBUTES_PROPERTY    = 'org.freedesktop.Secret.Item.Attributes'

    class Session(object):
        def __init__(self, parent):
            self.parent = parent
            self.session_path = None

        def __enter__(self):
            self.session_path = self.parent.main_iface.OpenSession('plain', '')[1]
            self.session = self.parent.get_object_iface(self.session_path, self.parent.SESSION_IFACE)
            return self

        def __exit__(self, type, value, traceback):
            self.session.Close()
            pass

    class Collection(object):
        SERVICE = 'SecureW2 JoinNow'
        ITEM_ID_NAME = 'pubkeyhash'

        CODEC = 'text/plain; charset=utf8'

        def __init__(self, parent, path, session):
            self.parent = parent
            self.session = session
            self.object = self.parent.get_object_proxy(path)
            self.main_iface = self.parent.get_object_iface(self.object, self.parent.COLLECTION_IFACE)

        def set(self, name, value, account=''):
            attributes = { 'service': self.SERVICE, 'account': account, self.ITEM_ID_NAME: name }
            label = self.SERVICE + ' - Private Key passphrase for ' + name
            properties = dbus.Dictionary({ self.parent.ITEM_LABEL_PROPERTY: label, self.parent.ITEM_ATTRIBUTES_PROPERTY: attributes })
            self.main_iface.CreateItem(properties, (self.session.session_path, '', value.encode('utf-8') if type(value) != bytes else value, self.CODEC), True)

        def _get_item(self, name):
            matches = self.main_iface.SearchItems(dbus.Dictionary({ 'service': self.SERVICE, self.ITEM_ID_NAME: name }))
            try:
                return self.parent.get_object_iface(matches[0], self.parent.ITEM_IFACE)
            except IndexError:
                return None

        def get(self, name):
            item = self._get_item(name)
            if item:
                return self.parent.decode_bytearray(item.GetSecret(self.session.session_path)[2])

        def delete(self, name):
            item = self._get_item(name)
            if item:
                return item.Delete()

    def __init__(self):
        super(SecretsServiceProxy, self).__init__()

    def session(self):
        return self.Session(self)

    def default_collection(self, session):
        return self.Collection(self, self.DEFAULT_COLLECTION_PATH, session)


class NetworkManagerProxy(DBusObjectProxy):
    BUS = dbus.SystemBus
    SERVICE = 'org.freedesktop.NetworkManager'

    PATH = '/org/freedesktop/NetworkManager'
    IFACE = 'org.freedesktop.NetworkManager'

    SETTINGS_PATH = '/org/freedesktop/NetworkManager/Settings'
    SETTINGS_IFACE = 'org.freedesktop.NetworkManager.Settings'
    SETTINGS_PERMISSION_DENIED_EXCEPTION = SETTINGS_IFACE + '.PermissionDenied'

    SETTINGS_CONN_IFACE = 'org.freedesktop.NetworkManager.Settings.Connection'
    ACTIVE_CONN_IFACE = 'org.freedesktop.NetworkManager.Connection.Active'
    DEVICE_IFACE = 'org.freedesktop.NetworkManager.Device'
    WLAN_DEVICE_IFACE = 'org.freedesktop.NetworkManager.Device.Wireless'
    ACCESS_POINT_IFACE = 'org.freedesktop.NetworkManager.AccessPoint'
    IP4CONFIG_IFACE = 'org.freedesktop.NetworkManager.IP4Config'

    DEVICE_TYPE_WIFI = 2

    def __init__(self):
        super(NetworkManagerProxy, self).__init__()

    def reopen(self):
        super(NetworkManagerProxy, self).reopen()
        self.settings_iface = self.get_object_iface(self.SETTINGS_PATH, self.SETTINGS_IFACE)

    def get_version(self):
        return self.get_object_property(self.PATH, 'Version', self.IFACE)

    @property
    def requires_explicit_hidden_ssid_scanning(self):
        version_parts = self.get_version().split('.')[:2]
        numeric_version = int(version_parts[0]) * 1000 + int(version_parts[1])
        return numeric_version < 1024

    def enable_wifi(self):
        self.set_object_property(self.PATH, 'WirelessEnabled', self.IFACE, True)

    def disable_wifi(self):
        self.set_object_property(self.PATH, 'WirelessEnabled', self.IFACE, False)

    def get_wlan_settings(self, ssid):
        c_uuid = str(uuid.uuid4())
        conn_settings = {
            'type': '802-11-wireless',
            'uuid': c_uuid,
            'id': ssid.name + ' [' + c_uuid[0:8] + ']',
            'autoconnect': ssid.autoconnect
        }
        ssid_settings = {
            'ssid': dbus.ByteArray(ssid.name.encode('utf-8')),
            'security': '802-11-wireless-security',
            'mode': [ 'infrastructure', 'adhoc' ][ssid.conntype]
        }

        #
        # NOTE: Only added when SSID is actually hidden to prevent possible API versioning issues
        #       (Cannot find any reference to this in the NetworkManager API reference)
        #
        if ssid.hidden:
            ssid_settings['hidden'] = True

        if ssid.priority != None:
            conn_settings['autoconnect-priority'] = ssid.priority

        security_settings = {}

        if   ssid.security == ssid.networksetting.SW2_PALADIN_SSID_SECURITYTYPE_WPA2Enterprise or \
             ssid.security == ssid.networksetting.SW2_PALADIN_SSID_SECURITYTYPE_WPAEnterprise:
            security_settings['key-mgmt'] = 'wpa-eap'
        elif ssid.security == ssid.networksetting.SW2_PALADIN_SSID_SECURITYTYPE_WPA2Personal or \
             ssid.security == ssid.networksetting.SW2_PALADIN_SSID_SECURITYTYPE_WPAPersonal:
            security_settings['key-mgmt'] = [ 'wpa-psk', 'wpa-none' ][ssid.conntype]
            security_settings['psk'] = ssid.networksetting.get_credentials().password
        elif ssid.security == ssid.networksetting.SW2_PALADIN_SSID_SECURITYTYPE_8021X:
            security_settings['key-mgmt'] = 'ieee8021x'
        else:
            security_settings['key-mgmt'] = 'none'

        security_settings['auth-alg'] = 'open'

        return dbus.Dictionary(conn_settings), dbus.Dictionary(ssid_settings), dbus.Dictionary(security_settings)

    def add_connection(self, s_con, s_wifi, s_wsec, s_8021x=None):
        s_ip4 = dbus.Dictionary({'method': 'auto'})
        s_ip6 = dbus.Dictionary({'method': 'auto'})
        con = {
            'connection': s_con,
            '802-11-wireless': s_wifi,
            '802-11-wireless-security': s_wsec,
            'ipv4': s_ip4,
            'ipv6': s_ip6
        }

        if s_8021x != None:
            con['802-1x'] = s_8021x

        setting = self.settings_iface.AddConnection(dbus.Dictionary(con))
        return self.get_uuid(setting)

    def add_psk_connection(self, ssid):
        s_con, s_wifi, s_wsec = self.get_wlan_settings(ssid)
        return self.add_connection(s_con, s_wifi, s_wsec)

    def add_eap_connection(self, ssid):
        s_con, s_wifi, s_wsec = self.get_wlan_settings(ssid)

        credentials = ssid.networksetting.get_credentials()

        eap_settings = {
            'eap': [ssid.networksetting.method], # peap, ttls,
            'identity': credentials.identity,
        }

        if credentials.type == credentials.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD:
            eap_settings['password'] = credentials.password
            eap_settings['password-flags'] = _long(0)
            eap_settings['phase2-auth'] = ssid.networksetting.method_phase2
        elif credentials.type == credentials.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD_TLSENROLLMENT or \
             credentials.type == credentials.SW2_PALADIN_CREDENTIALS_TYPE_WEBSSO_TLSENROLLMENT:
            eap_settings['client-cert'] = dbus_path(credentials.certificate.file)
            eap_settings['private-key'] = dbus_path(credentials.certificate.private_key.uri())
            eap_settings['private-key-password'] = credentials.certificate.private_key.passphrase
            eap_settings['private-key-password-flags'] = _long(0)

        if ssid.networksetting.server_validation:
            cert_uri = dbus_path(ssid.networksetting.get_certificate_file())
            if cert_uri != None:
                eap_settings['system-ca-certs'] = False
                eap_settings['ca-cert'] = cert_uri
            else:
                eap_settings['system-ca-certs'] = True
            if ssid.networksetting.servername != None and wpa_supplicant_version() >= 2.1:
                eap_settings['domain-suffix-match'] = ssid.networksetting.servername[2:] if ssid.networksetting.servername.startswith('*.') else ssid.networksetting.servername

        if ssid.networksetting.anonid:
            eap_settings['anonymous-identity'] = ssid.networksetting.anonid

        return self.add_connection(s_con, s_wifi, s_wsec, dbus.Dictionary(eap_settings))

    def delete_existing_connections(self, ssid, reset_wifi=True):
        """Checks and deletes existing *wireless* connections with the same @ssid"""
        conns = self.settings_iface.ListConnections()

        for conn in conns:
            connection = self.get_object_iface(conn, self.SETTINGS_CONN_IFACE)
            try:
                connection_settings = connection.GetSettings()
            except DBusException as e:
                if e.get_dbus_name() == self.SETTINGS_PERMISSION_DENIED_EXCEPTION:
                    continue
                raise

            if connection_settings['connection']['type'] == '802-11-wireless':  # make sure it's *wireless*
                conn_ssid = self.decode_bytearray(connection_settings['802-11-wireless']['ssid'])
                if conn_ssid.lower() == ssid.lower():
                    connection.Delete()

        if reset_wifi:
            self.disable_wifi()
            sleep(3)
            self.enable_wifi()

    def is_wireless(self, conn):
        """Checks if the given connection is a wireless connection"""
        connection = self.get_object_property(conn, 'Connection', self.ACTIVE_CONN_IFACE)
        connection_settings = self.get_object_iface(connection, self.SETTINGS_CONN_IFACE).GetSettings()
        return connection_settings['connection']['type'] == '802-11-wireless'

    def get_uuid(self, conn):
        connection = self.get_object_iface(conn, self.SETTINGS_CONN_IFACE)
        try:
            return connection.GetSettings()['connection']['uuid']
        except (KeyError, dbus.DBusException):
            print('Warning: failed to obtain connection UUID')
            return None

    def get_connection(self, uuid, retry=True):
        try:
            return self.settings_iface.GetConnectionByUuid(uuid)
        except dbus.DBusException as e:
            # Work-around for crashing daemon
            if retry and e.get_dbus_name() == 'org.freedesktop.DBus.Error.ServiceUnknown':
                self.reopen()
                return self.get_connection(uuid, False)
            return None

    def dev_get_property(self, nm_device, name):
        return self.get_object_property(nm_device, name, self.DEVICE_IFACE)

    def dev_get_wlan_property(self, nm_wlan_device, name):
        return self.get_object_property(nm_wlan_device, name, self.WLAN_DEVICE_IFACE)

    def dev_is_wlan(self, nm_device):
        return self.dev_get_property(nm_device, 'DeviceType') == self.DEVICE_TYPE_WIFI

    def dev_get_name(self, nm_device):
        return str(self.dev_get_property(nm_device, 'Interface'))

    def dev_get_ip4config_ip(self, nm_device):
        try:
            return str(next(iter(filter(lambda addrdata: 'address' in addrdata, self.get_object_property(self.dev_get_property(nm_device, 'Ip4Config'), 'AddressData', self.IP4CONFIG_IFACE))))['address'])
        except InvalidDBusObjectPathException as e:
            raise NoIp4ConfigAvailable('"%s" is not a valid Device or Ip4Config object' % str(e))
        except dbus.exceptions.DBusException:   # Assume missing 'AddressData' because of old API version
            raise NoIp4ConfigAddressDataAvailable('Ip4Config of Device %s does not have a "AddressData" property' % nm_device)
        except StopIteration:
            raise NoIp4ConfigAddressDataAvailable('Ip4Config of Device %s does not contain key "address"' % nm_device)

    def dev_get_legacy_ip(self, nm_device):
        ip4addr = int(self.dev_get_property(nm_device, 'Ip4Address'))
        return ('%d.%d.%d.%d' % (ip4addr / (2**0) & 0xff, ip4addr / (2**8) & 0xff, ip4addr / (2**16) & 0xff, ip4addr / (2**24) & 0xff)) if ip4addr else None

    def dev_get_ip(self, nm_device):
        try:
            return self.dev_get_ip4config_ip(nm_device)
        except (NoIp4ConfigAvailable, NoIp4ConfigAddressDataAvailable):
            return self.dev_get_legacy_ip(nm_device)

    def dev_get_macaddress(self, nm_device):
        return str(self.dev_get_wlan_property(nm_device, 'HwAddress'))

    def dev_get_ssid(self, nm_device):
        try:
            ap_dbus_path = self.dev_get_wlan_property(nm_device, 'ActiveAccessPoint')
            if ap_dbus_path in (None, '', '/'):
                return None
            return self.ap_get_ssid(ap_dbus_path)
        except InvalidDBusObjectPathException as e:
            return None

    def get_wireless_devices(self):
        return list(filter(lambda dev: self.dev_is_wlan(dev), self.main_iface.GetDevices()))

    def ap_get_ssid(self, ap):
        return self.decode_bytearray(self.get_object_property(ap, 'Ssid', self.ACCESS_POINT_IFACE))

    def connect(self, ssids, timeout):
        """Connects to one of the newly configured networks"""
        deadline = time.monotonic() + timeout

        adapters = self.get_wireless_devices()
        if len(adapters) == 0:
            return None, None

        while time.monotonic() < deadline:
            for adapter in adapters:
                try:
                    current_ssid = self.dev_get_ssid(adapter)
                    if current_ssid:
                        profile = ssids.find(current_ssid)
                        if not profile:
                            self.get_object_iface(adapter, self.DEVICE_IFACE).Disconnect()
                        else:
                            ip = self.dev_get_ip(adapter)
                            if ip:
                                return current_ssid, ip
                    else:
                        iface = self.get_object_iface(adapter, self.WLAN_DEVICE_IFACE)
                        aps = iface.GetAccessPoints()
                        matched = False
                        for ap in aps:
                            ssid = self.ap_get_ssid(ap)
                            profile = ssids.find(ssid)
                            if profile and profile.uuid:
                                conn = self.get_connection(profile.uuid)
                                if conn:
                                    matched = True
                                    self.main_iface.ActivateConnection(conn, adapter, "/")
                                    break
                        if not matched:
                            scan_args = {}
                            if self.requires_explicit_hidden_ssid_scanning and ssids.contains_hidden_ssid():
                                scan_args['ssids'] = [dbus.ByteArray(ssid.name.encode('utf-8')) for ssid in ssids.all()]
                            iface.RequestScan(dbus.Dictionary(scan_args))
                except DBusException as e:
                    # Lots of possibilities for exceptions here: SSIDs can come and go, USB interface might get unplugged
                    # Requesting a scan when already scanning is not allowed. All of these can be safely ignored.
                    pass
            sleep(0.5)
        return None, None


class GnomeShellProxy(DBusObjectProxy):
    BUS = dbus.SessionBus
    SERVICE = 'org.gnome.Shell'

    PATH = '/org/gnome/Shell'
    IFACE = 'org.gnome.Shell'

    def __init__(self):
        super(GnomeShellProxy, self).__init__()
        self.shell_iface = self.get_object_iface(self.PATH, self.IFACE)

    def eval(self, script):
        success, output = self.shell_iface.Eval(script)
        if not success:
            raise GnomeShellScriptExecutionException(output)
        return output

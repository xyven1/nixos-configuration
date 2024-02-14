import getpass
import os
import re
from base64 import b64decode
from hashlib import sha1
from subprocess import Popen, PIPE, STDOUT, CalledProcessError
from textwrap import wrap
from time import sleep

import websso
from dbusproxies import NetworkManagerProxy
from enroll import enroll, TPMRequired
from enrollapi import ConnectorError, EnrollmentException
from keystore import Certificate
from paladindefs import *
from reporter import PaladinCloudReporter
from resourcemanager import load_resources
from ui import Buttons
from xmlhelper import CloudConfigNodeWrapper


MAX_FILENAME_SIZE = 127     # Based on max 255 bytes assuming worst case scenario of 2 bytes per unicode character

class ActionError(Exception):
    REPORT_ERROR_CODE = None
    REPORT_ERROR_MESSAGE = None

    def __init__(self, parent, error, message):
        self.action = parent
        self.error = str(error) if not isinstance(error, Exception) else error.__class__.__name__
        if type(message) == int:
            message = self.action.get_string(message)
        if '%s' in message:
            message = message % (self.action.get_string(parent.ERROR_MSG) if type(parent.ERROR_MSG) == int else parent.ERROR_MSG)
        super(ActionError, self).__init__(message)

    def report_info(self):
        return (self.REPORT_ERROR_CODE, self.report_message())

    def report_message(self):
        message = self.REPORT_ERROR_MESSAGE
        try:
            if '%s' in message:
                return message % (self.action.sw2_action_type(), self.error)
        except TypeError:
            pass
        return message

class InternalActionError(ActionError):
    REPORT_ERROR_MESSAGE = 'Configuration failed [%s] (%s)'
    REPORT_ERROR_CODE = SW2_PALADIN_ERROR_INTERNAL

    def __init__(self, parent, error):
        super(InternalActionError, self).__init__(parent, error, parent.ERROR_MSG)

class UserCancelledException(ActionError):
    REPORT_ERROR_MESSAGE = InternalActionError.REPORT_ERROR_MESSAGE
    REPORT_ERROR_CODE = SW2_PALADIN_ERROR_USER_CANCELLED

    def __init__(self, parent, error='Cancelled'):
        super(UserCancelledException, self).__init__(parent, str(error), 116)


class ActionFactory(object):
    SW2_PALADIN_ACTION_TYPE_NONE                    = 0
    SW2_PALADIN_ACTION_TYPE_REPORT                  = 1
    SW2_PALADIN_ACTION_TYPE_LOCKSCREEN              = 2
    SW2_PALADIN_ACTION_TYPE_SETNEWPASSWORD          = 3
    SW2_PALADIN_ACTION_TYPE_ENABLEWLAN              = 4
    SW2_PALADIN_ACTION_TYPE_ADDWLAN                 = 5
    SW2_PALADIN_ACTION_TYPE_BACKUP                  = 6
    SW2_PALADIN_ACTION_TYPE_RESTORE                 = 7
    SW2_PALADIN_ACTION_TYPE_ADDCERTIFICATE          = 8
    SW2_PALADIN_ACTION_TYPE_CAMERA                  = 9
    SW2_PALADIN_ACTION_TYPE_WIPEDATA                = 10
    SW2_PALADIN_ACTION_TYPE_INSTALLSOFTWARE         = 11
    SW2_PALADIN_ACTION_TYPE_CONNECT                 = 12
    SW2_PALADIN_ACTION_TYPE_SETPROXYCONFIGURATION   = 13
    SW2_PALADIN_ACTION_TYPE_DISABLEWIRELESSONWIRED  = 14
    SW2_PALADIN_ACTION_TYPE_REBOOT                  = 15
    SW2_PALADIN_ACTION_TYPE_REMOVESSID              = 16
    SW2_PALADIN_ACTION_TYPE_GROUPACTION             = 17
    SW2_PALADIN_ACTION_TYPE_COPYFILE                = 18
    SW2_PALADIN_ACTION_TYPE_RUNCOMMAND              = 19
    SW2_PALADIN_ACTION_TYPE_REMOVESECUREW2          = 20
    SW2_PALADIN_ACTION_TYPE_SYSCHECK                = 21
    SW2_PALADIN_ACTION_TYPE_NAC                     = 22
    SW2_PALADIN_ACTION_TYPE_CREDENTIALS             = 23
    SW2_PALADIN_ACTION_TYPE_ENABLELAN               = 24
    SW2_PALADIN_ACTION_TYPE_ADDLAN                  = 25
    SW2_PALADIN_ACTION_TYPE_CUSTOMXML               = 26
    SW2_PALADIN_ACTION_TYPE_TIMECHECK               = 27
    SW2_PALADIN_ACTION_TYPE_ADDCERTIFICATEFIREFOX   = 28
    SW2_PALADIN_ACTION_TYPE_STARTFIREFOX            = 29
    SW2_PALADIN_ACTION_TYPE_STOPFIREFOX             = 30
    SW2_PALADIN_ACTION_TYPE_SMARTCARD               = 31
    SW2_PALADIN_ACTION_TYPE_ENROLL                  = 32
    SW2_PALADIN_ACTION_TYPE_CERTIFICATEREUSE        = 33
    SW2_PALADIN_ACTION_TYPE_OPENBROWSER             = 34
    SW2_PALADIN_ACTION_TYPE__LAST_                  = 35

    ActionMap = [ None ] * SW2_PALADIN_ACTION_TYPE__LAST_

    def __init__(self, parent):
        self.parent = parent
        self.register(ReportAction)
        self.register(AddCertificateAction)
        self.register(CredentialsAction)
        self.register(AddWLANAction)
        self.register(ConnectAction)
        self.register(OpenBrowserAction)
        self.ActionMap = [ am if am != None else NoneAction for am in self.ActionMap ]

    def create(self, actionconfig):
        type = int(actionconfig.get('type', 0))
        return self.ActionMap[type](self.parent, actionconfig)

    @classmethod
    def register(cls, actioncls):
        actioncls.register(cls.ActionMap)

class NoneAction(object):
    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_NONE
    ERROR_MSG = 175

    def __init__(self, parent, config=None):
        self.parent = parent
        self.resources = load_resources(config.findall('customization/resources/resource') if config != None else None, parent.resources)
        self.config = CloudConfigNodeWrapper(config)

        fail_action = self.config.int('failAction', required=False, default=SW2_PALADIN_ACTION_FAILACTION_TYPE_FAIL)
        self.ignore_errors = fail_action == SW2_PALADIN_ACTION_FAILACTION_TYPE_CONTINUE
        self.allow_continue_on_errors = fail_action == SW2_PALADIN_ACTION_FAILACTION_TYPE_PROMPT

    def run(self):
        pass

    def reset(self):
        pass

    def get_string(self, id):
        return self.resources.get_string(id)

    @classmethod
    def sw2_action_type(cls):
        name = cls.__name__.upper()
        if name[-6:] == 'ACTION':
            return 'SW2_PALADIN_ACTION_TYPE_' + name[:-6]

    @classmethod
    def register(cls, action_map):
        action_map[cls.ID] = cls

class ReportAction(NoneAction):
    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_REPORT
    ERROR_MSG = 141

    def __init__(self, parent, config):
        super(ReportAction, self).__init__(parent, config)

    def run(self):
        self.parent.reporter.report()

class AddCertificateAction(NoneAction):
    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_ADDCERTIFICATE
    ERROR_MSG = 146
    directory = '{0}/.joinnow'.format(os.environ.get('HOME', ''))
    certificates = {}
    bundles = []

    def __init__(self, parent, config):
        super(AddCertificateAction, self).__init__(parent, config)
        self.alias = self.config['certificate/alias']
        self.certificate = Certificate(self.config['certificate/data'])
        self.certificates[self.alias] = self

    def run(self):
        if self.directory and not os.path.exists(self.directory):
            os.makedirs(self.directory)
        self.writeout_certificate(self.open_certificate_file(self.alias))

    def writeout_certificate(self, certfile):
        self.certificate.write(certfile)

    @classmethod
    def get_filename(cls, alias):
        return os.path.join(cls.directory, '{0}.pem'.format(alias))

    @classmethod
    def open_certificate_file(cls, alias):
        return open(cls.get_filename(alias), 'w')

    @classmethod
    def get_or_create_bundle(cls, aliases):
        bundlename = '-'.join(aliases + [ 'bundle' ])
        if len(bundlename) > MAX_FILENAME_SIZE - 4:
            sorted_encoded_aliases = list([ alias.encode('utf-8') for alias in aliases ])
            sorted_encoded_aliases.sort()
            bundlename = '%s-%dcerts-bundle' % (sha1(b'\0'.join(sorted_encoded_aliases)).hexdigest(), len(sorted_encoded_aliases))
        if not bundlename in cls.bundles:
            with cls.open_certificate_file(bundlename) as certfile:
                for addcertaction in [ cls.certificates[alias] for alias in aliases ]:
                    addcertaction.writeout_certificate(certfile)
            cls.bundles += [ bundlename ]
        return bundlename

    @classmethod
    def get_filename_for_aliases(cls, aliases):
        if len(aliases) == 1:
            return cls.get_filename(aliases[0])
        bundlename = cls.get_or_create_bundle(aliases)
        return cls.get_filename(bundlename)

class CredentialsAction(NoneAction):
    SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD               = 0
    SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD_TLSENROLLMENT = 1
    SW2_PALADIN_CREDENTIALS_TYPE_WEBSSO_TLSENROLLMENT           = 2
    SW2_PALADIN_CREDENTIALS_TYPE_SHAREDSECRET                   = 3
    SW2_PALADIN_CREDENTIALS_TYPE_OSLOGONCREDS                   = 4
    SW2_PALADIN_CREDENTIALS_TYPE_OSLOGONCREDS_TLSENROLLMENT     = 5

    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_CREDENTIALS
    ERROR_MSG = 144

    Credentials = []

    class EnrollmentError(ActionError):
        REPORT_ERROR_MESSAGE = 'Enrollment failed [SW2_PALADIN_ACTION_TYPE_ENROLL] (%s)'
        REPORT_ERROR_CODE = SW2_PALADIN_ERROR_ENROLLMENT_FAILED

        def __init__(self, parent, message=176, client_error=1):
            if isinstance(client_error, ConnectorError):
                client_error = client_error.api_error
            if type(client_error) in [ tuple, list ]:
                if client_error[0] in [ 2, 3, 4 ]:
                    client_error = client_error[0] * 100 + client_error[1]
                else:
                    client_error = 1

            if message == 176:
                message = parent.get_string(message)
            else:
                message = '%s\n%s (%d)' % (parent.get_string(145), parent.get_string(message) if type(message) == int else message, client_error)

            super(CredentialsAction.EnrollmentError, self).__init__(parent, client_error, message)

        def report_message(self):
            return self.REPORT_ERROR_MESSAGE % self.error

    class EnrollmentAuthenticationError(EnrollmentError):
        def __init__(self, parent, api_error):
            super(CredentialsAction.EnrollmentAuthenticationError, self).__init__(parent, 177, api_error)

    class UserCertificateLimitReached(EnrollmentError):
        def __init__(self, parent, api_error):
            super(CredentialsAction.UserCertificateLimitReached, self).__init__(parent, 27, api_error)

    class ExternalUtilityRequired(ActionError):
        REPORT_ERROR_MESSAGE = 'External enrollment API not available [SW2_PALADIN_ACTION_TYPE_ENROLL] (%s)'
        REPORT_ERROR_CODE = SW2_PALADIN_ERROR_MISSING_ENROLLMENT_API

        def __init__(self, parent, error):
            message = parent.get_string(114)
            try:
                message = message % parent.get_string(145)
            except TypeError:
                pass
            super(CredentialsAction.ExternalUtilityRequired, self).__init__(parent, error, message)

        def report_message(self):
            return self.REPORT_ERROR_MESSAGE % self.error

    def __init__(self, parent, config):
        super(CredentialsAction, self).__init__(parent, config)
        self.Credentials += [ self ]
        self.identity = ''
        self.password = ''
        self.description = ''
        self.certificate = None
        credentials = self.config.credentials
        self.type = int(credentials.xml_node.get('type', self.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD))
        self.uuid = credentials.value('UUID', required=False)
        self.prompt = credentials.bool('prompt', default=True)
        self.identity_format = b64decode(credentials.value('matchText', default='Xi4qJA==')).decode('utf-8') if credentials.bool('useRegex', default=False) else None
        if self.identity_format != None:
            self.identity_template = b64decode(credentials.value('replaceText', default='XDA=')).decode('utf-8')
            self.regex = re.compile(self.identity_format)
        else:
            self.identity_template = None
            self.regex = None
        if self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_OSLOGONCREDS:
            self.type = self.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD
        elif self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_OSLOGONCREDS_TLSENROLLMENT:
            self.type = self.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD_TLSENROLLMENT
        if self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_SHAREDSECRET:
            self.password = credentials.value('PSK', required=False)
        elif self.type in (self.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD_TLSENROLLMENT, self.SW2_PALADIN_CREDENTIALS_TYPE_WEBSSO_TLSENROLLMENT):
            self.enrollconfig = credentials.TLSEnrollment

    def process_identity_template(self, match):
        try:
            from functools import reduce
        except:
            pass
        groups = ([ match.group(0) ] + list(match.groups('')) + ([ '' ] * 9))[:10]
        return reduce(
            lambda v, p:
                (v[0], p)                                                       if p == '\\' and (len(v) == 1 or v[1] != '\\') else \
                (v[0] + p,)                                                     if len(v) == 1 or (v[1] == '\\' and p == '\\') else \
                (v[0] + groups[int(p)],)                                        if p in '0123456789' and v[1] == '\\' else \
                (v[0] + (b'\\' + p.encode('utf-8')).decode('unicode_escape'),)  if p in "abfnrtv" and v[1] == '\\' else \
                (v[0], v[1] + 'x', '')                                          if p == 'x' and v[1] == '\\' else \
                (v[0] + p,)                                                     if len(v) == 2 else \
                (v[0] + chr(int(v[2] + p, 16)),)                                if v[2] != '' else \
                (v[0], v[1], p),
            self.identity_template,
            ('',)
        )[0]

    @staticmethod
    def verify_identity(self, input, window):
        if self.regex and not self.regex.match(input):
            return False, 24
        return True, (self.process_identity_template(self.regex.search(input)) if self.identity_template != None else None)

    @staticmethod
    def verify_repassword(self, input, window):
        if window.get_result(8) != input:
            return False, 23
        return True

    @staticmethod
    def verify_device_name(self, input, window):
        input = input.strip(' \t')
        if input == '':
            return False, 329
        return True

    @property
    def device_name_ui_callback(self):
        return None if not self.mandatory_device_name() else (self.verify_device_name, self)

    def prompt_for_device_name(self):
        return self.get_string(29).lower() != 'true'

    def mandatory_device_name(self):
        return self.get_string(53).lower() == 'true'

    def get_credentials(self, ui):
        if not self.prompt and not self.prompt_for_device_name():
            return

        window = ui.window()

        if self.prompt:
            window.add_message(6)
            window.add_prompt(7, verify_callback=(self.verify_identity, self))
            window.add_prompt(8, secret=True)

            if self.get_string(9).lower() != 'true':
                window.add_prompt(10, secret=True, verify_callback=(self.verify_repassword, self))

        if self.prompt_for_device_name():
            window.add_prompt(30, verify_callback=self.device_name_ui_callback)

        ui.execute(window)

        if self.prompt:
            self.identity = window.get_result(7)
            self.password = window.get_result(8)

        if self.prompt_for_device_name():
            self.description = window.get_result(30).strip(' \t')

    def get_psk(self, ui):
        window = ui.window()

        if self.prompt:
            window.add_message(6)
            window.add_prompt(None, result_key='psk')

        if self.prompt_for_device_name():
            window.add_prompt(30, verify_callback=self.device_name_ui_callback)

        ui.execute(window)

        if self.prompt:
            self.password = window.get_result('psk')

        if self.prompt_for_device_name():
            self.description = window.get_result(30)

    def do_websso_auth(self, ui):
        url_template = self.enrollconfig['webSSOUrl']
        auth_type = self.enrollconfig.int('webSSOConfirmType', default=1)

        def prepare_browser_invocation():
            try:
                return websso.prepare_callback(auth_type, url_template)
            except websso.NoBackendFoundException as e:
                if auth_type == SW2_PALADIN_TLS_ENROLL_WEBSSO_CONFIRM_TYPE_SCAN_TBAR:
                    try:
                        return websso.prepare_callback(SW2_PALADIN_TLS_ENROLL_WEBSSO_CONFIRM_TYPE_LOCAL_SERVER, url_template)
                    except Exception as _:
                        pass
                raise

        if auth_type not in websso.SUPPORTED_CONFIRM_TYPES:
            raise InternalActionError(self, 'webSSOConfirmType %d not supported' % auth_type)

        # HACK: When using the console UI, have a separate 'window' for the device name prompt
        from ui import ConsoleUI

        if type(ui) == ConsoleUI and self.prompt_for_device_name():
            window = ui.window()
            window.add_prompt(30, verify_callback=self.device_name_ui_callback)
            ui.execute(window)
            self.description = window.get_result(30)

        window = ui.window()
        window.add_message(6)

        if type(ui) != ConsoleUI and self.prompt_for_device_name():
            window.add_prompt(30, verify_callback=self.device_name_ui_callback)

        if ui.execute(window, buttons=[Buttons.NEXT, Buttons.CANCEL]) != Buttons.NEXT:
            raise UserCancelledException(self)

        if type(ui) != ConsoleUI and self.prompt_for_device_name():
            self.description = window.get_result(30)

        try:
            browser = websso.try_find_browser()
            url, wait_for_callback = prepare_browser_invocation()
            browser.navigate_to(url)
            result, attributes = wait_for_callback()
        except websso.WebSSOException as e:
            raise InternalActionError(self, e)

        if not result:
            raise UserCancelledException(self)

        if 'code' not in attributes:
            raise InternalActionError(self, 'Invalid WebSSO response attributes: ' + str(attributes))

        self.identity = ''
        self.password = attributes['code']
        return

    def run(self, ui):
        if self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD:
            self.get_credentials(ui)
        elif self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_USERNAMEPASSWORD_TLSENROLLMENT:
            self.get_credentials(ui)
            self.enroll(ui)
        elif self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_WEBSSO_TLSENROLLMENT:
            self.do_websso_auth(ui)
            self.enroll(ui)
        elif self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_SHAREDSECRET:
            self.get_psk(ui)

    def reset(self):
        self.password = ''
        self.certificate = None
        if self.type == self.SW2_PALADIN_CREDENTIALS_TYPE_SHAREDSECRET:
            self.password = self.config.credentials.value('PSK', required=False)

    def enroll(self, ui):
        try:
            self.certificate = enroll(self.enrollconfig, self, ui)
        except ConnectorError as e:
            if e.api_error[0] == 2 and e.api_error[1] in [ 1, 10 ]:
                raise self.EnrollmentAuthenticationError(self, e)
            if e.api_error == (3, 10):
                raise self.UserCertificateLimitReached(self, e)
            raise self.EnrollmentError(self, client_error=e)
        except TPMRequired as e:
            raise self.ExternalUtilityRequired(self, e)
        except EnrollmentException as e:
            raise self.EnrollmentError(self)

        self.identity = self.certificate.identity(fallback=(self.identity if self.identity not in (None, '') else 'anonymous'))

    @classmethod
    def get(cls, uuid):
        try:
            return next(iter(filter(lambda creds: creds.uuid == uuid, cls.Credentials)))
        except StopIteration:
            return None

class AddWLANAction(NoneAction):
    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_ADDWLAN
    ERROR_MSG = 150

    SW2_PALADIN_WLANPROFILE_TYPE_PERSONAL           = 0
    SW2_PALADIN_WLANPROFILE_TYPE_ENTERPRISE         = 1

    SW2_PALADIN_SSID_CONNECTIONTYPE_ESS             = 0
    SW2_PALADIN_SSID_CONNECTIONTYPE_IBSS            = 1

    SW2_PALADIN_WLANPROFILE_SCOPE_PERUSER           = 0
    SW2_PALADIN_WLANPROFILE_SCOPE_SYSTEM            = 1

    SW2_PALADIN_SSID_CONNECTIONMODE_AUTO            = 0
    SW2_PALADIN_SSID_CONNECTIONMODE_MANUAL          = 1

    SW2_PALADIN_SSID_SECURITYTYPE_WPA2Enterprise    = 0
    SW2_PALADIN_SSID_SECURITYTYPE_WPAEnterprise     = 1
    SW2_PALADIN_SSID_SECURITYTYPE_WPA2Personal      = 2
    SW2_PALADIN_SSID_SECURITYTYPE_WPAPersonal       = 3
    SW2_PALADIN_SSID_SECURITYTYPE_8021X             = 4
    SW2_PALADIN_SSID_SECURITYTYPE_CCKM              = 5
    SW2_PALADIN_SSID_SECURITYTYPE_Open              = 6
    SW2_PALADIN_SSID_SECURITYTYPE_Shared            = 7

    SW2_PALADIN_SSID_ENCRYPTIONTYPE_AES             = 0
    SW2_PALADIN_SSID_ENCRYPTIONTYPE_TKIP            = 1
    SW2_PALADIN_SSID_ENCRYPTIONTYPE_WEP             = 2
    SW2_PALADIN_SSID_ENCRYPTIONTYPE_NONE            = 3

    class SSID(object):
        SSIDs = []

        def __init__(self, parent, ssidconfig):
            self.SSIDs += [ self ]
            self.config = ssidconfig
            self.priority = self.config.int('priority')
            self.name = self.config['SSIDConfig/name']
            self.hidden = self.config.bool('SSIDConfig/nonBroadcast')
            self.conntype = self.config.int('connection/connectionType')
            self.autoconnect = True if self.config.int('connection/connectionMode') == AddWLANAction.SW2_PALADIN_SSID_CONNECTIONMODE_AUTO else False
            self.security = self.config.int('security/securityType')
            self.encryption = self.config.int('security/encryptionType')
            self.networksetting = parent
            self.uuid = None

        @classmethod
        def all(cls):
            return cls.SSIDs

        @classmethod
        def find(cls, name):
            try:
                return next(iter(filter(lambda ssid: ssid.name == name, cls.SSIDs)))
            except StopIteration:
                return None

        @classmethod
        def contains_hidden_ssid(cls):
            try:
                next(iter(filter(lambda ssid: ssid.hidden, cls.SSIDs)))
            except StopIteration:
                return False
            return True

    def __init__(self, parent, config):
        super(AddWLANAction, self).__init__(parent, config)

        profile = self.config.WLANProfile
        self.credentials_uuid = profile.value('credentialsUUID', required=False)

        self.type = int(profile.xml_node.get('type', self.SW2_PALADIN_WLANPROFILE_TYPE_ENTERPRISE))
        self.profilename = profile['name']
        self.scope = profile.int('scope', default=self.SW2_PALADIN_WLANPROFILE_SCOPE_PERUSER)
        self.ssids = [ self.SSID(self, ssid) for ssid in profile.findall('SSIDs/SSID') ]

        if self.type == self.SW2_PALADIN_WLANPROFILE_TYPE_ENTERPRISE:
            eapconfig = profile.EAP
            self.method = eapconfig['eapMethod'].lower()
            try:
                self.method_phase2 = eapconfig.value('eapPhase2', required=False).lower()
            except AttributeError:
                self.method_phase2 = None
            self.anonid = eapconfig.value('anonymousIdentity', default='')
            if len(self.anonid) == 0:
                self.anonid = None
            self.server_validation = eapconfig.bool('enableServerValidation')
            if self.server_validation:
                self.cacerts = eapconfig.findall('CACertificates/certificate/alias', values=True)
                self.servername = eapconfig.value('serverNames', default='')
                if len(self.servername) == 0:
                    self.servername = None
            else:
                self.cacerts = None
                self.servername = None


    def run(self):
        nm = NetworkManagerProxy()
        for ssid in self.ssids:
            nm.delete_existing_connections(ssid.name)
            if ssid.networksetting.type == ssid.networksetting.SW2_PALADIN_WLANPROFILE_TYPE_ENTERPRISE:
                ssid.uuid = nm.add_eap_connection(ssid)
            elif ssid.networksetting.type == ssid.networksetting.SW2_PALADIN_WLANPROFILE_TYPE_PERSONAL:
                ssid.uuid = nm.add_psk_connection(ssid)

    def get_certificate_file(self, default=None):
        if self.type != self.SW2_PALADIN_WLANPROFILE_TYPE_ENTERPRISE:
            return default
        if len(self.cacerts) == 0:
            return default
        return AddCertificateAction.get_filename_for_aliases(self.cacerts)

    def get_credentials(self):
        return CredentialsAction.get(self.credentials_uuid)

class ConnectAction(NoneAction):
    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_CONNECT
    ERROR_MSG = 156

    class ConnectionFailedException(ActionError):
        REPORT_ERROR_MESSAGE = 'Connection failed'
        REPORT_ERROR_CODE = PaladinCloudReporter.ERROR_CONNECTION_FAILED_OTHER

        def __init__(self, parent, message=103):
            super(ConnectAction.ConnectionFailedException, self).__init__(parent, None, message)

    class ConnectionTimedOutException(ActionError):
        REPORT_ERROR_MESSAGE = 'Connection timed out'
        REPORT_ERROR_CODE = PaladinCloudReporter.ERROR_CONNECTION_TIMED_OUT

        def __init__(self, parent, message=104):
            super(ConnectAction.ConnectionTimedOutException, self).__init__(parent, None, message)

    def __init__(self, parent, config):
        super(ConnectAction, self).__init__(parent, config)

    def run(self):
        print('\n' + self.get_string(65))
        ssid, ip = NetworkManagerProxy().connect(AddWLANAction.SSID, timeout=SW2_PALADIN_WLAN_CONNECTION_TIMEOUT)
        self.parent.reporter.set_ipaddress(ip)

        if ssid:
            connected_profile = AddWLANAction.SSID.find(ssid)

            #
            # If we are connected to a network, use appropriate identity instead of last configured one
            #
            if connected_profile:
                try:
                    self.parent.reporter.set_identity(connected_profile.networksetting.get_credentials().identity)
                except AttributeError:
                    pass

                self.parent.reporter.sendconfiguration(0, 'Connection to "%s" succeeded' % ssid)
            else:
                raise self.ConnectionFailedException(self)
        else:
            raise self.ConnectionTimedOutException(self)


class OpenBrowserAction(NoneAction):
    ID = ActionFactory.SW2_PALADIN_ACTION_TYPE_OPENBROWSER
    ERROR_MSG = 172

    def __init__(self, parent, config):
        super(OpenBrowserAction, self).__init__(parent, config)
        self.url = self.config.value('redirectUrl')
        self.delay = self.config.int('redirectAfter', required=False)

    def open_url(self):
        try:
            websso.try_find_browser().navigate_to(self.url)
        except websso.WebSSOException as e:
            raise InternalActionError(self, e)

    def run(self):
        if self.delay is not None and self.delay > 0:
            sleep(self.delay / 1000)
        self.open_url()

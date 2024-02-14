import re
import xml.etree.ElementTree as ET
from locale import getdefaultlocale
from subprocess import Popen, PIPE

from pycompat import getargspec, urlopen, URLError

VERSION = '3.0.2'
NAME    = 'JoinNow for Linux'

from actions import ActionFactory, NoneAction, ActionError, InternalActionError
from logger import function_logger
from paladindefs import SW2_PALADIN_REPORT_HANDLER_CLOUD
from reporter import PaladinCloudReporter
from resourcemanager import load_resources
from ui import ui, Buttons


class PaladinLinuxClient(object):
    """SecureW2 JoinNow Linux Client Implementation"""
    CONFIG_FILE = 'SecureW2.cloudconfig'

    def __init__(self):
        self.devicecfg       = None
        self.organization    = None
        self.actions         = []
        self.locales         = []

        config_file = self.decipher(self.CONFIG_FILE)
        config_file = self.strip_namespace(config_file)
        self.load_config(config_file)

    @staticmethod
    def decipher(config_file):
        with open(config_file) as config:
            p = Popen('openssl smime -verify -inform der -noverify', stdin=config, stdout=PIPE, shell=True)
            config_data = p.communicate()[0]
            return bytearray(config_data).decode('utf-8')

    @staticmethod
    def strip_namespace(xml_document):
        """Removes xmlns attribute from XML file to avoid having to prefix all nodes"""
        return re.sub('xmlns="[^"]+"', '', xml_document)

    def load_config(self, xml_document):
        """Parses the XML config file"""
        try:
            root = ET.fromstring(xml_document)
        except UnicodeEncodeError:
            root = ET.fromstring(xml_document.encode('utf-8'))

        #
        # Find organization node
        #
        self.organization = (root.findall('organization') + [ None ])[0]

        #
        # Find (first) deviceconfig node
        #
        self.devicecfg = root.find('configurations/deviceConfiguration')

        #
        # Read reporting config and initialize reporter
        #
        try:
            reporting = next(iter(filter(lambda n: int(n.get('type', '0')) == SW2_PALADIN_REPORT_HANDLER_CLOUD, self.devicecfg.findall('reporting/handlers/handler'))))
        except StopIteration:
            reporting = None

        self.reporter = PaladinCloudReporter(reporting, self.devicecfg, self.organization)
        self.resources = load_resources(self.devicecfg.findall('customization/resources/resource'))

        #
        # Create actions
        #
        factory = ActionFactory(self)
        self.actions = [ factory.create(a) for a in self.devicecfg.findall('actions/action') ]

    def set_success(self, message=None):
        self.success = True
        self.message = message if message != None else 67

    def set_error(self, message):
        self.succeess = False
        self.message = message

    def run(self, mask_exceptions=True, handle_errors=True):
        def handle_action_error(e, allow_continue=False):
            try:
                self.reporter.sendconfiguration(*e.report_info())
            except Exception as _:
                pass
            result = client_ui.show_message(str(e), buttons=[Buttons.RETRY, Buttons.CANCEL if not allow_continue else Buttons.CONTINUE])
            return result == Buttons.RETRY

        self.success = False
        self.message = None
        retry = False

        client_ui = ui(self.resources)

        try:
            for action in self.actions:
                client_ui.enter_action(action)
                try:
                    try:
                        if 'ui' in getargspec(action.run).args:
                            action.run(ui=client_ui)
                        else:
                            action.run()
                    except Exception as e:
                        if not mask_exceptions:
                            raise
                        raise e if isinstance(e, ActionError) else InternalActionError(action, e)
                except ActionError as e:
                    if action.ignore_errors:
                        pass
                    elif handle_errors and action.allow_continue_on_errors:
                        retry = handle_action_error(e, allow_continue=True)
                        if retry:
                            break
                    else:
                        raise
                client_ui.leave_action()
            if not retry:
                self.set_success()
        except ActionError as e:
            if not handle_errors:
                print(e.__class__.__name__ + ': ' + e.error)
                raise
            retry = handle_action_error(e)

        if retry:
            self.reset()
            return self.run()

        if self.success:
            self.reporter.sendconfiguration(0, 'Configuration succeeded')

        if self.message:
            client_ui.show_message(self.message, buttons=[Buttons.DONE])

    def reset(self):
        for action in self.actions:
            action.reset()

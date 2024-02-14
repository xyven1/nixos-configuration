from locale import getdefaultlocale

BUILDIN_STRINGS = {
    6:  'Please enter your credentials',
    7:  'Enter your Username:',
    8:  'Enter your Password:',
    9:  'false',
    10: 'Re-Enter your Password:',
    11: 'Enter your domain:',
    12: 'true',
    14: 'Next',
    15: 'Skip',
    16: 'Continue',
    17: 'Cancel',
    18: 'Done',
    19: 'Retry',
    23: 'Passwords do not match',
    24: 'The username is not correctly formatted for this network.',
    27: 'You have reached the maximum allowed devices to be enrolled for your account. To connect this device, you must remove one of the other devices connected by revoking the certificate issued to an older/unused device.\r\nPlease contact your IT Administrator help revoke an old certificate and re-run this application',
    29: 'true',
    30: 'Name your device:',
    35: 'JoinNow MultiOS by SecureW2',
    53: 'false',
    64: 'Configuring...',
    65: 'Connecting...',
    67: 'Joined...',
    103: 'Configuration succeeded. Configured Network is however not in range.\r\n\r\nClick on the wireless tray icon to validate if your network is available. If you are seeing intermittent issues or low signal strength please move your device to re-establish a better connection and retry.',
    104: 'Configuration succeeded. Configured Network is however not in range.\r\n\r\nClick on the wireless tray icon to validate if your network is available. If you are seeing intermittent issues or low signal strength please move your device to re-establish a better connection and retry.',
    114: '%s\r\nAn external program required for certificate enrollment was not found or is not working correctly.',
    116: '%s\r\nReason: Aborted by user.',
    141: 'Could not report.',
    142: 'Could not lock the screen.',
    143: 'Could not set new password.',
    144: 'Could not continue with credentials collection.',
    145: 'Failed to enroll for certificate.',
    146: 'Could not add certificate.',
    148: 'Could not enable wireless network.',
    150: 'Could not configure wireless network.',
    151: 'Could not run backup',
    152: 'Could not restore.',
    153: 'Could not run camera.',
    154: 'Could not process with wipe data.',
    155: 'Could not install software',
    156: 'Could not connect to network.',
    157: 'Could not set proxy configuration.',
    158: 'Could not run disasble wireless on wired.',
    159: 'Could not reboot.',
    160: 'Could not remove SSID.',
    161: 'Could not group action.',
    162: 'Could not copy file.',
    163: 'Could not run command.',
    164: 'Could not remove SecureW2.',
    165: 'Could not run SysCheck.',
    166: 'Could not run NAC.',
    172: 'Could not open browser.',
    175: 'General error.',
    176: 'Enrollment failed. Please contact your network administrator.',
    177: 'Enrollment failed due to an authentication error.\r\n\r\nThe most likely reason for authentication failure is a username / password validation problem. Please retry with new credentials.',
    178: 'The enrollment server does not support the requested enrollment type, please contact your Administrator.',
    251: 'Generating Key...',
    252: 'Enrolling Certificate...',
    253: 'Issued',
    329: 'A device name is required'
}

locales = None

def get_effective_locales():
    global locales
    if locales == None:
        locales = []
        locale = getdefaultlocale()[0]
        if locale:
            if len(locale.split('_')) > 1:
                locales += [ locale.split('_')[0] ]
            locales += [ locale ]

        if not 'en' in locales:
            locales = [ 'en' ] + locales
    return locales

class ResourcesView(object):
    def __init__(self, strings):
        self.strings = strings

    def get_string(self, id):
        try:
            return self.strings[id]
        except KeyError:
            try:
                return BUILDIN_STRINGS[id]
            except KeyError:
                return ''

def load_resources(resources, basedata={}):
    if isinstance(basedata, ResourcesView):
        basedata = basedata.strings
    strings = basedata.copy()
    if not resources:
        return ResourcesView(strings)
    for locale in get_effective_locales():
        for res in resources:
            use = False
            for res_locale in res.findall('locales/locale'):
                if res_locale.text == locale:
                    use = True
                    break
            if not use:
                continue
            for string in res.findall('strings/string'):
                strings[int(string.find('id').text)] = string.find('text').text
    return ResourcesView(strings)


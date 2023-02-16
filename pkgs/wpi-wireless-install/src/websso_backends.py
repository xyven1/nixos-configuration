from os import environ, getcwd, mkdir

from pycompat import parse_qsl

from detect import detect_executable, ExecutableNotFoundError, ExternalExecutionError, VERBOSE_DETECT
from dbusproxies import GnomeShellProxy, GnomeShellScriptExecutionException, DBusException


class WebSSOError(Exception):
    pass

class WebSSOBackendError(WebSSOError):
    pass

class NoX11DisplayEnvironmentVariable(Exception):
    def __init__(self):
        super(NoX11DisplayEnvironmentVariable, self).__init__('DISPLAY environment variable was not set')

class UnsupportedConfigurationException(Exception):
    pass


def detect_failed(cls, e):
    if VERBOSE_DETECT:
        print('%s was not detected on the system: %s: %s. Attempting next implementation.' % (cls.__name__, e.__class__.__name__, e))
    return False


class Window(object):
    def __init__(self, manager=None):
        self.id = None
        self.title = None
        self.manager = manager

    def minimize(self):
        if self.manager != None:
            return self.manager.minimize(self.id)
        return False

    def __str__(self):
        return '%s (0x%08x)' % (self.title if self.title != None else '<NO TITLE>', self.id if self.id != None else -1)


class FreeDesktopMimeAppsBrowserLauncher(object):
    def __init__(self):
        pass

    @classmethod
    def detected(cls):
        try:
            if 'DISPLAY' not in environ or environ['DISPLAY'] == '':
                raise NoX11DisplayEnvironmentVariable()
            cls.executable = detect_executable('xdg-open')
            return True
        except (NoX11DisplayEnvironmentVariable, ExecutableNotFoundError) as e:
            return detect_failed(cls, e)

    def navigate_to(self, url):
        try:
            self.executable.run_silent(url, background=True)
        except ExternalExecutionError as e:
            raise WebSSOBackendError(e)


class AbstractWindowsScanner(object):
    def scan_for_window_title(self, criteria):
        return filter(lambda window: criteria(window.title), self.all_windows())


class XWinInfoWindowScanner(AbstractWindowsScanner):
    class XWinInfoWindow(Window):
        def __init__(self, info, manager):
            super(XWinInfoWindowScanner.XWinInfoWindow, self).__init__(manager)
            self.id = int(info.split(' ', 1)[0], 16)
            if info.split(' ', 1)[1][0] == '"':
                self.title = info.split(' ', 1)[1][1:].split('":')[0]

    executable = None

    def __init__(self):
        super(XWinInfoWindowScanner, self).__init__()
        try:
            from x11 import WindowManager
            self.window_manager = WindowManager()
        except ImportError:
            raise
            self.window_manager = None

    @classmethod
    def detected(cls, fallback=False):
        try:
            if 'DISPLAY' not in environ or environ['DISPLAY'] == '':
                raise NoX11DisplayEnvironmentVariable()
            if not fallback and 'XDG_SESSION_TYPE' in environ and environ['XDG_SESSION_TYPE'] != 'x11':
                raise UnsupportedConfigurationException('Not a pure X11 session: xwininfo might not be able to correctly detect browser titlebar contents')
            cls.executable = detect_executable('xwininfo')
            return True
        except (NoX11DisplayEnvironmentVariable, ExecutableNotFoundError) as e:
            return detect_failed(cls, e)

    def all_windows(self):
        try:
            return filter(lambda w: w.title != None and w.title != '', [ XWinInfoWindowScanner.XWinInfoWindow(wi, self.window_manager) for wi in filter(lambda s: s[0:2] == '0x', [ l.strip(' ') for l in self.executable.run_and_get_output('-tree', '-root').split('\n') ]) ])
        except ExternalExecutionError:
            return []   # Known issue, just ignore


class GnomeShellWindowScanner(AbstractWindowsScanner):
    SCRIPT = 'global.get_window_actors().map((w, idx) => [idx, w.get_meta_window().get_title()])'

    class Minimizer(object):
        SCRIPT = 'global.get_window_actors()[%d].get_meta_window().minimize()'

        def __init__(self, parent):
            self.proxy = parent.proxy

        def minimize(self, index):
            self.proxy.eval(self.SCRIPT % index)

    @classmethod
    def detected(cls, fallback=False):
        try:
            proxy = GnomeShellProxy()
            return proxy.eval('true')
        except (ImportError, GnomeShellScriptExecutionException, DBusException) as e:
            return detect_failed(cls, e)

    def __init__(self):
        super(GnomeShellWindowScanner, self).__init__()
        self.proxy = GnomeShellProxy()
        self.manager = self.Minimizer(self)

    def all_windows(self):
        class Wrapper(Window):
            def __init__(self, manager, index, title):
                super(Wrapper, self).__init__(manager)
                self.id = index
                self.title = title if title is not None else ''

        import json
        return [ Wrapper(self.manager, index, title) for index, title in json.loads(self.proxy.eval(self.SCRIPT)) ]


browserlaunchers = [FreeDesktopMimeAppsBrowserLauncher]
windowscanners = [GnomeShellWindowScanner, XWinInfoWindowScanner]


for cls in windowscanners:
    try:
        if cls.detected(fallback=True):
            FallbackWindowScanner = cls
        if cls.detected():
            WindowScanner = cls
            break
    except Exception as e:
        detect_failed(cls, e)


for cls in browserlaunchers:
    try:
        if cls.detected():
            BrowserLauncher = cls
            break
    except Exception as e:
        detect_failed(cls, e)

if VERBOSE_DETECT:
    print(' -->  Using %s as browser launcher implementation' % BrowserLauncher.__name__)
    try:
        print(' -->  Using %s as window scanner implementation (fallback mode)' % FallbackWindowScanner.__name__)
        print(' -->  Using %s as window scanner implementation' % WindowScanner.__name__)
    except NameError:
        print(' !!!  No compatible window scanner implementation found')

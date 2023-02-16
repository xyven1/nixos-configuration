from time import sleep
from uuid import uuid4

from paladindefs import *
from pycompat import parse_qsl, urlencode, urlparse, urlunparse


OAUTH_OOB_URN = 'urn:ietf:wg:oauth:2.0:oob:auto'
OAUTH_OOB_RESULT_TEXT = [
    'Success ',
    'Denied '
]
SUPPORTED_CONFIRM_TYPES = [
    SW2_PALADIN_TLS_ENROLL_WEBSSO_CONFIRM_TYPE_SCAN_TBAR,
    SW2_PALADIN_TLS_ENROLL_WEBSSO_CONFIRM_TYPE_LOCAL_SERVER
]

AUTH_FINISHED_URL = 'https://cloud.securew2.com/sso/'

class WebSSOException(Exception):
    pass

class NoBackendFoundException(WebSSOException):
    def __init__(self, error):
        super(NoBackendFoundException, self).__init__('No supported WebSSO backend found: ' + str(error))


def is_oauth_oob_window(title, state):
    if not state in title:
        return False
    for result_text in OAUTH_OOB_RESULT_TEXT:
        if result_text in title:
            return True
    return False

def try_find_browser():
    try:
        from websso_backends import BrowserLauncher
        return BrowserLauncher()
    except ImportError as e:
        raise NoBackendFoundException(e)


def run_local_server(state):
    try:
        from http.server import HTTPServer, BaseHTTPRequestHandler
    except ImportError as e:
        raise NoBackendFoundException(str(e))

    class CallbackRequestHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            params = dict(parse_qsl(urlparse(self.path).query))
            if 'state' in params and params['state'] == state:
                self.close_connection = True
                self.send_response(302)
                self.send_header('Location', AUTH_FINISHED_URL)
                self.end_headers()
                self.server.response = params
            else:
                self.send_response(500)
                self.end_headers()
        def log_message(self, *_):
            pass

    class CallbackServer(HTTPServer):
        def __init__(self):
            super(CallbackServer, self).__init__(('127.0.0.1', 0), CallbackRequestHandler)
            self.response = None

        def wait_for_response(self):
            while self.response is None:
                self.handle_request()
            return True, self.response

    return CallbackServer()


def prepare_callback(confirm_type, url_template):
    if '%TRANSACTIONID%' not in url_template:
        raise WebSSOException('WebSSO requires %TRANSACTIONID% variable in url')

    uuid = str(uuid4())
    url = url_template.replace('%TRANSACTIONID%', uuid)

    if confirm_type == SW2_PALADIN_TLS_ENROLL_WEBSSO_CONFIRM_TYPE_SCAN_TBAR:
        try:
            from websso_backends import WindowScanner
        except ImportError as e:
            raise NoBackendFoundException(str(e))

        scanner = WindowScanner()
        scan_for_windows = lambda: scanner.scan_for_window_title(lambda title: is_oauth_oob_window(title, uuid))
        current_titles = [ w.title for w in scan_for_windows() ]
        possible_results = [ x.strip(' ') for x in OAUTH_OOB_RESULT_TEXT ]

        def wait_for_result():
            while True:
                sleep(0.1)
                try:
                    window = next(iter(filter(lambda w: w.title not in current_titles, scan_for_windows())))
                except StopIteration:
                    continue
                parts = window.title.split(' ')
                while len(parts) > 1:
                    if parts[0] in possible_results:
                        window.minimize()
                        return possible_results.index(parts[0]) == 0, dict(parse_qsl(parts[1]))
                    parts = parts[1:]

        return url, wait_for_result

    elif confirm_type == SW2_PALADIN_TLS_ENROLL_WEBSSO_CONFIRM_TYPE_LOCAL_SERVER:
        parsed_url = urlparse(url)
        query = dict(parse_qsl(parsed_url.query))
        if 'redirect_uri' in query:
            redirect_url = query['redirect_uri']
            if redirect_url != OAUTH_OOB_URN and redirect_url != '' and redirect_url[:16] != 'http://localhost':
                raise WebSSOException('Unsupported redirect URL for LOCAL_SERVER WebSSO confirmation type')
        server = run_local_server(uuid)
        query['redirect_uri'] = 'http://localhost:%d/' % server.server_port
        url = urlunparse(parsed_url[:4] + (urlencode(query), ''))

        def wait_for_result():
            result = server.wait_for_response()
            try:
                #
                # Attempt to minimize browser if possible
                # (Depends if a window scanner is available and the browser is running under the correct window manager/compositor)
                # Ignore any errors.
                #
                from websso_backends import FallbackWindowScanner
                windows = []
                attempts = 5
                while len(windows) == 0 and attempts > 0:
                    attempts -= 1
                    sleep(1)
                    windows = list(FallbackWindowScanner().scan_for_window_title(lambda title: AUTH_FINISHED_URL in title or True))
                    for window in windows:
                        window.minimize()
            except Exception as e:
                pass
            return result

        return url, wait_for_result

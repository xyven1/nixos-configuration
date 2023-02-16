import sys
import time

if sys.version_info > (3,):
    from urllib.request import urlopen, Request
    from urllib.error import URLError, HTTPError
    from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse
    import http.client as httplib

    long = int
else:
    from urllib import urlencode
    from urllib2 import urlopen, Request, URLError, HTTPError
    from urlparse import parse_qsl, urlparse, urlunparse
    import httplib

try:
    from _io import TextIOWrapper, BufferedReader
    try:
        FILETYPES = (file, TextIOWrapper, BufferedReader)
    except NameError:
        FILETYPES = (TextIOWrapper, BufferedReader)
except ImportError:
    FILETYPES = (file,)

try:
    from json import JSONDecodeError
except ImportError:
    JSONDecodeError = ValueError

try:
    from inspect import getfullargspec as getargspec
except ImportError:
    try:
        from inspect import getargspec
    except ImportError:
        pass
    raise

try:
    raw_input
except NameError:
    raw_input = input

_long = long
_raw_input = raw_input


try:
    time.monotonic()
except AttributeError:
    time.monotonic = time.time


from base64 import b64encode, b64decode
from hashlib import sha1
from json import loads, dumps
from os import urandom

from pycompat import urlopen, Request as HttpRequest, URLError, HTTPError
from pycompat import JSONDecodeError

from sslengine import SSLEngineError


VERSION = '1.4'


class EnrollmentException(Exception):
    pass

class InvalidConnectorResponseException(EnrollmentException):
    pass

class ConnectorError(EnrollmentException):
    def __init__(self, error):
        super(ConnectorError, self).__init__('Error during certificate enrollment: server returned error %d - %d' % error)
        self.api_error = error

class Connector(object):
    REQUEST_HEADERS = { 'Content-Type': 'application/json' }
    def __init__(self, url):
        self.url = url
        self.version = VERSION
        self.protocol_extensions = []

    def send(self, json):
        if type(json) != bytes:
            json = json.encode('utf-8')
        req = HttpRequest(self.url, json, self.REQUEST_HEADERS)
        try:
            conn = urlopen(req)
            return conn.read()
        except (URLError, HTTPError) as e:
            raise InvalidConnectorResponseException('Error during certificate enrollment: Error sending HTTP request: %s' % str(e))

    def negotiate_version(self):
        VersionRequest(self).send()
        return self.version

class Response(object):
    def __init__(self, connector, request, response_json, check_version=True, autoraise=False, accepted_types=None):
        if accepted_types == None:
            accepted_types = [ request.TYPE ]
        self.connector = connector
        self.request = request
        try:
            self.data = loads(response_json.decode('utf-8'))
        except (ValueError, JSONDecodeError) as e:
            raise InvalidConnectorResponseException('Error during certificate enrollment: Unable to parse server response: ' + str(e))
        if not self['type'] in accepted_types:
            raise InvalidConnectorResponseException('Error during certificate enrollment: Unable to parse server response: Received unexpected response of type "%s"' % self['type'])
        if check_version and self['version'] != connector.version:
            raise InvalidConnectorResponseException('Error during certificate enrollment: Unable to parse server response: Received response for unexpected protocol version %s' % self['version'])
        self.success = True if self['error'] == 0 else False
        self.error = None if self.success else (self['error'], self['detailedError'])
        if autoraise:
            self.raise_on_error()

    def __getitem__(self, key):
        try:
            return self.data[key]
        except KeyError:
            raise InvalidConnectorResponseException('Error during certificate enrollment: Unable to parse server response (missing mandatory key "%s")' % key)

    def raise_on_error(self):
        if not self.success:
            raise ConnectorError(self.error)

class VersionResponse(Response):
    def __init__(self, connector, request, response_json):
        super(VersionResponse, self).__init__(connector, request, response_json, check_version=False, autoraise=True)
        if self.connector.version != self['version']:
            my_version = self.connector.version.split('.')
            remote_version = self['version'].split('.')
            if my_version[:-1] == remote_version[:-1] and remote_version[-1] <= my_version[-1]:
                self.connector.version = str(self['version'])
            else:
                raise InvalidConnectorResponseException('Error during certificate enrollment: Unable to parse server response: Server returned unexpected protocol version %s' % self['version'])
        self.connector.protocol_extensions = self['extensions'] if 'extensions' in self.data else []

class ChallengeResponse(Response):
    def __init__(self, connector, request, response_json):
        super(ChallengeResponse, self).__init__(connector, request, response_json, autoraise=True)
        self.transaction = self['transaction-id']
        self.challenges = self['challenges']

    def get_raw(self, challenge_id):
        return b64decode(self.challenges[challenge_id]) if challenge_id in self.challenges else None

class EnrollmentResponse(Response):
    def __init__(self, connector, request, response_json):
        super(EnrollmentResponse, self).__init__(connector, request, response_json, accepted_types=request.TYPES, autoraise=True)
        self.certificates = self['signedCertificates']

class Request(object):
    RESPONSE_CLASS = Response

    def __init__(self, connector):
        self.connector = connector

    def json(self):
        return dumps(dict(self))

    def send(self):
        response = self.connector.send(self.json())
        return self.RESPONSE_CLASS(self.connector, self, response)

    def __iter__(self):
        yield 'version', self.connector.version
        yield 'type', self.TYPE

class VersionRequest(Request):
    TYPE = 'getVersion'
    RESPONSE_CLASS = VersionResponse

class ChallengeRequest(Request):
    TYPE = 'challengeRequest'
    RESPONSE_CLASS = ChallengeResponse
    CHALLENGE_SIZE = 64

    def __init__(self, connector, certificates=[]):
        super(ChallengeRequest, self).__init__(connector)
        self.challenge_ids = []
        for certificate in filter(lambda c: c.private_key != None, certificates):
            self.challenge_ids += [ ClientCertAuthentication.certificate_challenge_name(certificate) ]

    def __iter__(self):
        for k, v in super(ChallengeRequest, self).__iter__(): yield k, v
        yield 'requests', [ { 'name': id, 'length': self.CHALLENGE_SIZE } for id in self.challenge_ids ]

class EnrollmentRequest(Request):
    TYPE = 'enroll'
    RENEW_TYPE = 'renew'
    TYPES = [ TYPE, RENEW_TYPE ]
    RESPONSE_CLASS = EnrollmentResponse

    def __init__(self, connector, identity, authentication=[], certificate_requests=[], device_attributes={}, current_certificates=[], challenges_response=None, metadata={}):
        super(EnrollmentRequest, self).__init__(connector)
        self.identity = identity
        self.certificate_requests = certificate_requests
        self.device_attributes = device_attributes
        self.metadata = metadata
        self.certificates = list(filter(lambda c: c.private_key != None, current_certificates))
        self.authentication = authentication if type(authentication) == list else [ authentication ]
        if challenges_response != None:
            for c in self.certificates:
                try:
                    challenge_id = ClientCertAuthentication.certificate_challenge_name(c)
                    self.authentication += [ ClientCertAuthentication(c, (challenge_id, challenges_response.get_raw(challenge_id))) ]
                except KeyError:
                    pass
            self.transaction = challenges_response.transaction

    def challenge_value(self):
        return b64encode(dumps([ dict(a) for a in self.authentication ]).encode('utf-8')).decode('utf-8')

    def __iter__(self):
        for k, v in super(EnrollmentRequest, self).__iter__():
            if k == 'type':
                yield k, self.TYPE if len(self.certificates) == 0 else self.RENEW_TYPE
            else:
                yield k, v
        yield 'identity', self.identity
        yield 'challenge', self.challenge_value()
        if hasattr(self, 'transaction'):
            yield 'transaction-id', self.transaction
        yield 'certificateRequests', self.certificate_requests
        yield 'clientCertificate', [ c.base64() for c in self.certificates ]
        yield 'deviceAttributes', self.device_attributes
        yield 'configInfo', self.metadata

class PasswordAuthentication(object):
    TYPE = 0

    def __init__(self, password):
        self.password = password

    def __iter__(self):
        yield 'type', self.TYPE
        yield 'value', self.password

class ClientCertAuthentication(object):
    TYPE = 1
    CLIENT_NONCE_LEN = 64

    def __init__(self, certificate, server_nonce):
        self.certificate = certificate
        self.server_nonce_id = server_nonce[0]
        self.nonces = (server_nonce[1], urandom(self.CLIENT_NONCE_LEN))

    def __iter__(self):
        yield 'type', self.TYPE
        yield 'challenge', self.server_nonce_id
        yield 'clientNonce', b64encode(self.nonces[1]).decode('utf-8')
        try:
            yield 'value', b64encode(self.certificate.private_key.sign(sha1(b''.join(self.nonces)).digest())).decode('utf-8')
        except (IOError, SSLEngineError):
            yield 'value', ''

    @staticmethod
    def certificate_challenge_name(certificate):
        return 'ClientCert' + certificate.sha1() + '-Challenge'


from base64 import b64encode
from datetime import datetime
from errno import ENOENT
from os import path, unlink, walk, mkfifo, getpid, rename
from subprocess import check_call, CalledProcessError
from tempfile import TemporaryFile, NamedTemporaryFile

from detect import detect_executable, ExecutableNotFoundError, ExternalExecutionError

OPENSSL_CSR_CLIENT_CERT_CONFIG = """
[req]
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[req_distinguished_name]

[v3_req]
keyUsage = digitalSignature, nonRepudiation
extendedKeyUsage = clientAuth

[dir_sect]
"""

OPENSSL_RSA_ENCRYPT_FLAG = '-aes256'

try:
    openssl = detect_executable('openssl')
except ExecutableNotFoundError as e:
    raise ImportError('Unable to import %s: unable to locate openssl executable' % __name__)

class SSLEngineError(Exception):
    pass

class AsnDecodingError(SSLEngineError):
    pass

class TemporaryInputFile(object):
    def __init__(self, data='', suffix=''):
        self.extension = suffix
        if type(data) == str and type(data) != bytes:
            data = data.encode('utf-8')
        self.data = data

    def __enter__(self):
        self.tempfile = NamedTemporaryFile(suffix=self.extension)
        self.tempfile.write(self.data)
        self.tempfile.flush()
        return self.tempfile

    def __exit__(self, type, value, traceback):
        self.tempfile.close()

class PregeneratedTemporaryOutputFileName(object):
    def __init__(self, suffix=''):
        self.extension = suffix

    def __enter__(self):
        tempfile = NamedTemporaryFile(delete=False, suffix=self.extension)
        tempfile.close()
        self.filename = tempfile.name
        return self.filename

    def __exit__(self, type, value, traceback):
        try:
            unlink(self.filename)
        except OSError as e:
            if e.errno != ENOENT:
                raise

class PassphraseFile(object):
    def __init__(self, passphrase):
        self.passphrase = passphrase.encode('utf-8') if type(passphrase) != bytes else passphrase
        self.file = TemporaryFile()

    def __enter__(self):
        self.file.write(self.passphrase)
        self.file.flush()
        return self.name()

    def __exit__(self, type, value, traceback):
        self.file.close()

    def name(self):
        return '/proc/%d/fd/%d' % (getpid(), self.file.fileno())

class PrivateKeyEncryptionFlags(PassphraseFile):
    def __init__(self, passphrase):
        if passphrase != None:
            super(PrivateKeyEncryptionFlags, self).__init__(passphrase)
        else:
            self.file = None

    def __enter__(self):
        if self.file != None:
            filename = super(PrivateKeyEncryptionFlags, self).__enter__()
            return [ OPENSSL_RSA_ENCRYPT_FLAG, '-passout', 'file:' + filename ]
        return []

    def __exit__(self, type, value, traceback):
        if self.file != None:
            super(PrivateKeyEncryptionFlags, self).__exit__(type, value, traceback)

class PrivateKeyDecryptionFlags(PassphraseFile):
    def __init__(self, passphrase, force=False):
        if passphrase != None or force:
            super(PrivateKeyDecryptionFlags, self).__init__(passphrase if passphrase != None else '')
        else:
            self.file = None

    def __enter__(self):
        if self.file != None:
            filename = super(PrivateKeyDecryptionFlags, self).__enter__()
            return [ '-passin', 'file:' + filename ]
        return []

    def __exit__(self, type, value, traceback):
        if self.file != None:
            super(PrivateKeyDecryptionFlags, self).__exit__(type, value, traceback)

def detect_tpm():
    # FIXME: Improve
    try:
        if len(next(walk('/sys/class/tpm'))[1]) == 0:
            return False
    except StopIteration:   # Directory does not exist: not supported by kernel
        return False
    try:
        detect_executable('stpm-keygen')
    except ExecutableNotFoundError:
        return False
    return True

def run_openssl(*arguments):
    try:
        return openssl.run_silent(*arguments)
    except ExternalExecutionError as e:
        raise SSLEngineError(e)

class AsnObject(str):
    pass

class AsnBitString(object):
    def __init__(self, _):      # Not supported
        pass

class AsnOctetString(object):
    def __init__(self, raw_data):
        self.raw = raw_data

    def __bytes__(self):
        return self.raw

    def __str__(self):
        return self.__bytes__().decode('utf-8')

    @classmethod
    def parse_hex(cls, hexdata):
        return cls(bytes(bytearray([ int(hexdata[i:i+2], 16) for i in range(0, len(hexdata), 2) ])))

    def parse_asn(self, cls=None):
        return parse_asn(self.__bytes__(), cls=(OpenSSLAsnStructure if cls == None else cls))

class AsnRDNSet(object):
    CONVERSION_TABLE = {
        'c':    'countryName',
        'cn':   'commonName',
        'dc':   'domainComponent',
        'e':    'emailAddress',
        'l':    'localityName',
        'st':   'stateOrProvinceName',
        'o':    'organizationName',
        'ou':   'organizationalUnitName'
    }

    def __init__(self, dn):
        self.raw = [ OpenSSLAsnStructure.avp(rdn) for rdn in dn ]

    def _rdn(self, rdn):
        try:
            return next(iter(filter(lambda avp: rdn in avp.keys(), self.raw)))[rdn]
        except StopIteration:
            return None

    def __getattr__(self, attr):
        if attr in self.CONVERSION_TABLE.keys():
            return self._rdn(self.CONVERSION_TABLE[attr])
        raise AttributeError(attr)

    def __getitem__(self, key):
        value = self._rdn(self.CONVERSION_TABLE[key])
        if value == None:
            raise KeyError(key)
        return value

    def __iter__(self):
        for k in self.CONVERSION_TABLE.keys():
            try:
                self[k]
                yield k
            except KeyError:
                pass

class OpenSSLAsnStructure(object):
    def __init__(self, process_output, raw_data=None):
        self.raw = self.parse(process_output, raw_data)

    @staticmethod
    def _mergeup(context, depth=0):
        for d in range(len(context) - 1, depth, -1):
            if context[d][0] == 'cont' and '_cur' in context[d][1]:
                del context[d][1]['_cur']
            if context[d-1][0] == 'cont':
                k = context[d-1][1]['_cur'] if '_cur' in context[d-1][1] else list(context[d-1][1].keys())[-1]
                context[d-1][1][k] = context[d][1]
            else:
                context[d-1][1].append(context[d][1] if context[d][0] != 'SEQUENCE' else tuple(context[d][1]))
            del context[d]

    @classmethod
    def parse(cls, process_output, raw_data):
        context = {}
        for line in process_output.split('\n'):
            line = line.lstrip(' ')
            if line == '':
                continue
            pos, line = line.split(' ', 1)
            pos, depth = [ int(x) for x in pos.split(':d=', 1) ]
            sectionlen = int(line.split(' l=', 1)[1].lstrip(' ').split(' ')[0])
            value = line.split(': ', 1)[1]
            value = value.split(':', 1)
            valtype = value[0].rstrip(' ')
            idx = None
            if '[' in valtype:
                valtype = valtype.split('[')[0].rstrip(' ')
                if valtype == 'cont':
                    idx = int(list(filter(lambda s: s != '', value[0].split(' ')))[2])
            value = value[1] if len(value) > 1 else None
            if valtype in ('SEQUENCE', 'SET'):
                value = []
            elif valtype == 'cont':
                value = { idx: AsnOctetString(raw_data[pos+2:pos+2+sectionlen]) if raw_data != None else None, '_cur': idx }
            elif valtype == 'INTEGER':
                value = int(value, 16)
            elif valtype == 'BOOLEAN':
                value = int(value) != 0
            elif valtype in ('IA5STRING', 'PRINTABLESTRING', 'UTF8STRING', 'T61STRING'):
                pass
            elif valtype == 'UTCTIME':
                value = datetime.strptime(value, '%y%m%d%H%M%SZ')
            elif valtype == 'OBJECT':
                value = AsnObject(value)
            elif valtype == 'NULL':
                value = None
            elif valtype == 'BIT STRING':
                value = AsnBitString(value)
            elif valtype == 'OCTET STRING':
                value = AsnOctetString.parse_hex(value)
            else:                           # Unknown value type
                value = None
            if len(context) > depth:
                cls._mergeup(context, depth)
            if depth in context and depth > 0:
                if valtype == 'cont' and context[depth][0] == 'cont':
                    context[depth][1][idx] = value[idx]
                    context[depth][1]['_cur'] = idx
                    value = context[depth][1]
                else:
                    cls._mergeup(context, depth - 1)
            context[depth] = ( valtype, value )

        cls._mergeup(context)
        return tuple(context[0][1])

    @classmethod
    def load(cls, file, format='PEM', raw_data=None):
        if not type(file) == str:
            file = file.name
        if raw_data == None and format == 'DER':
            with open(file, 'rb') as input_file:
                raw_data = input_file.read()
        try:
            return cls(openssl.run_and_get_output('asn1parse', '-in', file, '-inform', format), raw_data)
        except ExternalExecutionError as e:
            raise AsnDecodingError('Failed to decode ASN blob: %s\nBase64:\n%s' % (str(e), b64encode(raw_data)))

    @staticmethod
    def avp(value):
        if type(value) != list:
            value = [ value ]
        for av in value:
            if type(av) != tuple or len(av) != 2 or not isinstance(av[0], AsnObject):
                raise AsnDecodingError('Not a generic ASN name-value pair: ' + str(av))
        return dict(value)

class CertificateExtension(object):
    def __init__(self, data):
        self.type = data[0]
        self.critical = False if len(data) < 3 or type(data[1]) != bool else data[1]
        self.value = data[-1]

class CertificateInfo(OpenSSLAsnStructure):
    def __init__(self, process_output, raw_data=None):
        super(CertificateInfo, self).__init__(process_output, raw_data)

    def signedinfo(self):
        return self.raw[0]

    def version(self):
        return self.signedinfo()[0][0] + 1

    def serial_nr(self):
        return self.signedinfo()[1]

    def issuer(self):
        return AsnRDNSet(self.signedinfo()[3])

    def subject(self):
        return AsnRDNSet(self.signedinfo()[5])

    def cn(self):
        return self.subject().cn

    def name(self, include_organization=True, include_organizational_unit=True):
        subject = self.subject()
        name = subject.cn
        if include_organizational_unit and 'ou' in subject:
            name += ', ' + subject.ou
        if include_organization and 'o' in subject:
            name += ', ' + subject.o
        return name

    def valid_from(self):
        return self.signedinfo()[4][0]

    def valid_till(self):
        return self.signedinfo()[4][1]

    def extensions(self):
        if len(self.signedinfo()) > 7 and self.version() == 3 and 3 in self.signedinfo()[7]:
            return dict([ (e[0], CertificateExtension(e)) for e in self.signedinfo()[7][3] ])

    def extension(self, id):
        extensions = self.extensions()
        if extensions != None and id in extensions:
            return extensions[id]

    def subject_key_id(self):
        ski = self.extension('X509v3 Subject Key Identifier')
        if ski != None:
            return bytes(ski.value.raw)

    def san(self):
        san = self.extension('X509v3 Subject Alternative Name')
        if san != None:
            san_data = san.value.parse_asn()
            if san_data != None and len(san_data.raw) > 0:
                return san_data.raw[0]

    def upn(self):
        san = self.san()
        if san != None and 0 in san:
            return san[0][0]

    def rfc822name(self):
        san = self.san()
        if san != None and 1 in san:
            return str(san[1])

def parse_asn(raw_data, cls=OpenSSLAsnStructure, format='DER'):
    with TemporaryInputFile(raw_data, suffix='.bin') as input_file:
        return cls.load(input_file, format=format, raw_data=(raw_data if format == 'DER' else None))

def read_certificate_file(certificate_file, format='PEM'):
    return CertificateInfo.load(certificate_file, format)

def read_certificate(certificate, format='DER'):
    with TemporaryInputFile(certificate, suffix='.crt') as certificate_file:
        return read_certificate_file(certificate_file, format=format, raw_data=(raw_data if format == 'DER' else None))

def generate_software_key(private_key_path, passphrase, size):
    with PrivateKeyEncryptionFlags(passphrase) as encryption_flags:
        run_openssl('genrsa', '-out', private_key_path, *(encryption_flags + [ str(size) ]))

def generate_tpm_key(private_key_path, size):
    # FIXME: Error out if size != 2048 ?
    detect_executable('stpm-keygen').run_silent('-r', '-o', private_key_path)

def key_valid(private_key_path, passphrase=None, engine=None):
    if engine == None and private_key_path[-4:].lower() == '.p12':
        if passphrase == None:
            return False
        try:
            with TemporaryOpenSSLKeyFile(private_key_path, passphrase) as keyfile:
                return key_valid(keyfile, passphrase)
        except SSLEngineError:
            return False
    with PrivateKeyDecryptionFlags(passphrase, force=True) as decryption_flags:
        args = [ 'rsa', '-in', private_key_path ]
        args += decryption_flags
        if engine != None:
            args += [ '-engine', engine, '-keyform', 'engine' ]
        args += [ '-noout' ]
        try:
            run_openssl(*args)
            return True
        except SSLEngineError:
            return False

def generate_csr(private_key_path, cn, format='der', passphrase=None, engine=None):
    if engine == None and private_key_path[-4:].lower() == '.p12':
        with TemporaryOpenSSLKeyFile(private_key_path, passphrase) as keyfile:
            return generate_csr(keyfile, cn, format=format, passphrase=passphrase)
    with PregeneratedTemporaryOutputFileName(suffix='.csr') as csrfile_name:
        with TemporaryInputFile(OPENSSL_CSR_CLIENT_CERT_CONFIG, suffix='.conf') as configfile:
            with PrivateKeyDecryptionFlags(passphrase) as decryption_flags:
                args = [ 'req', '-config', configfile.name, '-batch' ]
                if engine != None:
                    args += [ '-engine', engine, '-keyform', 'engine' ]
                args += decryption_flags
                args += [ '-key', private_key_path, '-new', '-subj', '/CN=%s' % (cn if cn != '' else 'anonymous') , '-out', csrfile_name, '-outform', format ]
                run_openssl(*args)
                with open(csrfile_name, 'rb' if format == 'der' else 'r') as csrfile:
                    return csrfile.read()

def sign_raw_data(data, private_key_path, passphrase=None, engine=None):
    if engine == None and private_key_path[-4:].lower() == '.p12':
        with TemporaryOpenSSLKeyFile(private_key_path, passphrase) as keyfile:
            return sign_raw_data(data, keyfile, passphrase=passphrase)
    with PregeneratedTemporaryOutputFileName(suffix='.sig') as signature_file:
        with TemporaryInputFile(data, suffix='.bin') as inputfile:
            with PrivateKeyDecryptionFlags(passphrase) as decryption_flags:
                args = [ 'rsautl' ]
                if engine != None:
                    args += [ '-engine', engine, '-keyform', 'engine' ]
                args += decryption_flags
                args += [ '-in', inputfile.name, '-inkey', private_key_path, '-out', signature_file, '-sign' ]
                run_openssl(*args)
                with open(signature_file, 'rb') as sigfile:
                    return sigfile.read()

def encrypt_private_key(private_key_path, old_passphrase=None, new_passphrase=None, encryption_type='openssl', certificate=None):
    if encryption_type.lower() not in ['openssl', 'pem', 'der', 'pkcs12', 'p12']:
        raise Exception('Invalid private key encryption type "%s".' % encryption_type)

    pkcs12 = encryption_type.lower()[:2] == 'pk' or certificate != None

    with PrivateKeyDecryptionFlags(old_passphrase) as decryption_flags:
        with PrivateKeyEncryptionFlags(new_passphrase) as encryption_flags:
            old_private_key_path = private_key_path + '.old'
            rename(private_key_path, old_private_key_path)

            try:
                if not pkcs12:
                    run_openssl('rsa', '-in', old_private_key_path, '-out', private_key_path, *(decryption_flags + encryption_flags))
                else:
                    if private_key_path[-4:] in [ '.pem', '.der', '.key' ]:
                        private_key_path = private_key_path[:-4] + '.p12'
                        certificate_flags = [ '-in', certificate ] if certificate != None else [ '-nocerts' ]
                    run_openssl('pkcs12', '-export', '-inkey', old_private_key_path, '-out', private_key_path, *(certificate_flags + decryption_flags + encryption_flags))
            finally:
                try:
                    unlink(old_private_key_path)
                except (IOError, OSError):
                    pass
                return private_key_path


class TemporaryOpenSSLKeyFile(object):
    def __init__(self, pkcs12file, passphrase):
        self.pkcs12file = pkcs12file
        self.keyfile = (pkcs12file[:-4] if pkcs12file[-4:].lower() == '.p12' else pkcs12file) + '.key'
        self.passphrase = passphrase

    def __enter__(self):
        with PrivateKeyDecryptionFlags(self.passphrase) as decryption_flags:
            with PrivateKeyEncryptionFlags(self.passphrase) as encryption_flags:
                run_openssl('pkcs12', '-in', self.pkcs12file, '-nocerts', '-nomacver', '-out', self.keyfile, *(decryption_flags + encryption_flags))
        return self.keyfile

    def __exit__(self, type, value, traceback):
        unlink(self.keyfile)


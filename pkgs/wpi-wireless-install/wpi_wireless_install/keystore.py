import binascii
import os
import re
from base64 import b64encode, b64decode
from hashlib import sha1
from textwrap import wrap
from os import environ, makedirs, path, unlink

from pycompat import FILETYPES

from sslengine import generate_software_key, generate_tpm_key, key_valid, encrypt_private_key, generate_csr, sign_raw_data, detect_tpm, read_certificate, read_certificate_file, SSLEngineError
from secrets import SecretStorage, generate_temporary_secret

class PrivateKeyExists(Exception):
    pass

class CertificateNotFound(Exception):
    pass

class BadPrivateKeyException(Exception):
    pass

class NoSubjectNameFoundException(AttributeError):
    pass

def keystore_directory():
    return path.join(environ.get('HOME', ''), '.joinnow', 'tls-client-certs')

def simple_tpm_directory():
    return path.join(environ.get('HOME', ''), '.simple-tpm-pk11')

class Certificate(object):
    def __init__(self, certificate, private_key=None):
        self.private_key = private_key
        self.file = None
        self.fileformat = None
        if isinstance(certificate, FILETYPES):
            self.file = certificate.name
            self.fileformat = 'DER'
            certificate = certificate.read()
        try:
            encoded = certificate if type(certificate) == str else certificate.decode('utf-8')
            if encoded[0:11] == '-----BEGIN ':
                encoded = ''.join(filter(lambda line: line[0:5] != '-----' or line[-5:] != '-----', encoded.split('\n')))
            decoded = b64decode(encoded)
            if b64encode(decoded).decode('utf-8') == encoded:
                certificate = decoded
            self.fileformat = 'PEM'
        except binascii.Error:
            pass
        self.raw = certificate
        self._parsed = None

    def base64(self, pem=False):
        base64 = b64encode(self.raw).decode('utf-8')
        if not pem:
            return base64
        return '-----BEGIN CERTIFICATE-----\n{0}\n-----END CERTIFICATE-----\n'.format('\n'.join(wrap(base64, width=64)))

    def sha1(self, raw=False):
        hash = sha1(self.raw)
        return hash.hexdigest() if not raw else hash.digest()

    def write(self, destination, der=False):
        if not isinstance(destination, FILETYPES):
            if self.file == None:
                self.file = destination
            with open(destination, 'w' if not der else 'wb') as f:
                return self.write(f, der)

        destination.write(self.base64(True) if not der else self.raw)

        if self.file == None:
            self.file = destination.name

        if self.file == destination.name:
            destination.close()
            if self.private_key != None:
                self.private_key.certificate_updated(self)

    def delete(self, delete_private_key=True):
        if self.file != None:
            unlink(self.file)
            self.file = None
        if delete_private_key and self.private_key != None:
            self.private_key.delete()

    @classmethod
    def load(cls, filename, private_key=None):
        with open(filename, 'rb') as f:
            return cls(f, private_key)

    def parse(self):
        if self._parsed == None:
            if self.file != None:
                self._parsed = read_certificate_file(self.file, format=self.fileformat)
            else:
                self._parsed = read_certificate(self.raw)
        return self._parsed

    def identity(self, allowed_sources=[ 'upn', 'rfc822name', 'cn' ], fallback=None):
        info = self.parse()
        for getter in filter(lambda f: f != None and callable(f), [ getattr(info, s) for s in allowed_sources ]):
            try:
                value = getter()
                if value != None and len(value) > 0:
                    return value
            except (AttributeError, ValueError, KeyError, SSLEngineError):
                pass
        if fallback != None:
            return fallback
        raise NoSubjectNameFoundException('No valid subject name found in certificate. Tried: ' + ', '.join(allowed_sources))

class SoftwareKey(object):
    def __init__(self, keyfile, passphrase=None, name=None, store=None):
        self.name = name
        self.passphrase = passphrase
        self.store = store
        self.file = keyfile

        if self.passphrase == None and path.exists(self.file) and not key_valid(self.file):
            certificate = self.certificate()
            if certificate != None:
                passphrase = SecretStorage.get_private_key_secret(certificate)
                if passphrase != None and key_valid(self.file, passphrase=passphrase):
                    self.passphrase = passphrase

        if path.exists(self.file) and not key_valid(self.file, passphrase=self.passphrase):
            raise BadPrivateKeyException('Unable to read private key "%s".' % keyfile)

    def uri(self):
        return 'file://' + self.file

    def certificate(self):
        if self.name == None or self.store == None:
            return None
        if not self.store.certificate_exists(self.name):
            return None
        return Certificate.load(self.store.certificate_path(self.name), self)

    def generate_csr(self, cn):
        return generate_csr(self.file, cn, passphrase=self.passphrase)

    def sign(self, data):
        return sign_raw_data(data, self.file, passphrase=self.passphrase)

    def delete(self):
        unlink(self.file)
        self.file = None

        if self.passphrase != None:
            certificate = self.certificate()
            if certificate != None:
                SecretStorage.delete_private_key_secret(certificate)

    def certificate_updated(self, certificate):
        new_passphrase = SecretStorage.generate_private_key_secret(certificate)
        self.file = encrypt_private_key(self.file, old_passphrase=self.passphrase, new_passphrase=new_passphrase, encryption_type='pkcs12', certificate=certificate.file)
        self.passphrase = new_passphrase

class SoftwareStore(object):
    KEY_SUFFIX = '.key'
    PKCS12_KEY_SUFFIX = '.p12'
    CERT_SUFFIX = '.crt'

    def __init__(self, directory=None, create=True):
        self.directory = directory if directory != None else keystore_directory()
        if not path.exists(self.directory):
            makedirs(self.directory)

    def private_key_path(self, name):
        key_path = path.join(self.directory, name + self.KEY_SUFFIX)
        pkcs12_key_path = path.join(self.directory, name + self.PKCS12_KEY_SUFFIX)

        if path.isfile(pkcs12_key_path):
            return pkcs12_key_path
        return key_path

    def certificate_path(self, name):
        if isinstance(name, SoftwareKey):
            name = name.name
        return path.join(self.directory, name + self.CERT_SUFFIX)

    def find_objects(self, suffix):
        return [ f.rstrip(suffix) for f in filter(lambda o: self.object_has_suffix(o, suffix), next(os.walk(self.directory))[2]) ]

    def key_exists(self, name):
        return path.isfile(self.private_key_path(name))

    def certificate_exists(self, name):
        return path.isfile(self.certificate_path(name))

    def generate(self, name, size=2048, overwrite=False):
        if not overwrite and self.key_exists(name):
            raise PrivateKeyExists(name)
        keyfile = self.private_key_path(name)
        passphrase = generate_temporary_secret()
        generate_software_key(keyfile, passphrase, size=size)
        return SoftwareKey(keyfile, passphrase=passphrase, name=name, store=self)

    def certificate(self, name, load_key=None):
        if not self.certificate_exists(name):
            raise CertificateNotFound(self.certificate_path(name))
        if load_key == None:
            load_key = self.key_exists(name)
        return Certificate.load(self.certificate_path(name), private_key=(SoftwareKey(self.private_key_path(name), name=name, store=self) if load_key else None))

    def certificates(self, with_private_key=False):
        certificates = []
        for certname in self.find_objects(self.CERT_SUFFIX):
            if not with_private_key or self.key_exists(certname):
                try:
                    certificates += [ self.certificate(certname) ]
                except BadPrivateKeyException:
                    if not with_private_key:
                        certificates += [ self.certificate(certname, load_key=False) ]
                except IOError:
                    pass
        return certificates

    @staticmethod
    def object_has_suffix(object, suffix):
        suffix_len = len(suffix)
        return object[-suffix_len:] == suffix

    @staticmethod
    def strip_suffix(object, suffix):
        suffix_len = len(suffix)
        if object[-suffix_len:] == suffix:
            return object[:-suffix_len]
        return object

class TPMKey(object):
    TOKEN_LABEL_PREFIX = 'sw2-joinnow-'
    TOKEN_LABEL_MAX_SIZE = 32

    def __init__(self, keyconfigfile, name=None, store=None):
        self.name = name
        self.store = store
        self.keyconfigfile = keyconfigfile
        self.read_keyconfig_file()

    def uri(self):
        return 'pkcs11:token=' + self.label.replace(' ', '%20')

    def read_keyconfig_file(self):
        with open(self.keyconfigfile) as kcf:
            config = dict(self.Store.read_settings(kcf.read().split('\n')))
            self.keyfile = self.calculate_path(kcf, config['key'])
            self.certfile = self.Store.strip_suffix(self.keyfile, self.Store.KEY_SUFFIX) + self.Store.CERT_SUFFIX
            try:
                self.label = config['name']
            except AttributeError:
                self.label = 'Simple-TPM-PK11 token'

    def certificate(self):
        if path.isfile(self.certfile):
            return Certificate.load(self.certfile, self)

    def generate_csr(self, cn):
        return generate_csr(self.uri(), cn, engine='pkcs11')

    def sign(self, data):
        return sign_raw_data(data, self.uri(), engine='pkcs11')

    def delete(self):
        unlink(self.keyfile)
        unlink(self.keyconfigfile)
        if self.store != None:
            self.store.deregister(self.keyconfigfile)

    def certificate_updated(self, certificate):
        pass

    @classmethod
    def create(cls, name, key_file, store, label=None, register=False):
        path = store.keyconfig_path(name)
        keyconfig = {
            'key': key_file,
            'name': label if label != None else (cls.TOKEN_LABEL_PREFIX + sha1(key_file.encode('utf-8')).hexdigest())[:cls.TOKEN_LABEL_MAX_SIZE-1]
        }
        with open(path, 'w') as f:
            f.write('\n'.join([ ' '.join([ k, v ]) for k, v in keyconfig.items() ]))
        key = cls(path, name=name, store=store)
        if register:
            store.register(key)
        return key

    @staticmethod
    def calculate_path(origin, relative_path):
        if relative_path[0] == os.sep:
            return relative_path
        if isinstance(origin, FILETYPES):
            origin = origin.name
        if path.isfile(origin):
            origin = path.dirname(origin)
        return path.join(origin, relative_path)

class TPMEnhancedSoftwareStore(SoftwareStore):
    KEYCONFIG_SUFFIX = '.keyconfig'
    KEYCONFIG_SETTING_NAME = 'key_config'

    def __init__(self, directory=None, create=True):
        self.directory = directory if directory != None else simple_tpm_directory()
        self.configfile = path.join(self.directory, 'config')
        if not path.exists(self.directory):
            makedirs(self.directory)

    def keyconfig_path(self, name):
        return path.join(self.directory, name + self.KEYCONFIG_SUFFIX)

    def certificate_path(self, name):
        if isinstance(name, TPMKey):
            return name.certfile
        return super(TPMEnhancedSoftwareStore, self).certificate_path(name)

    def key_exists(self, name):
        return path.isfile(self.keyconfig_path(name))

    def generate(self, name, size=2048, overwrite=False, label=None):
        if not overwrite and self.key_exists(name):
            raise PrivateKeyExists(name)

        keyfile = self.private_key_path(name)
        generate_tpm_key(keyfile, size=size)

        return TPMKey.create(name, keyfile, self, label=label, register=True)

    def keys(self):
        return [ TPMKey(kc, store=self, name=(self.strip_suffix(kc, self.KEYCONFIG_SUFFIX).split(os.sep)[-1])) for kc in self.load_keyconfigs() ]

    def certificates(self, with_private_key=None):
        return list(filter(lambda c: c != None, [ key.certificate() for key in self.keys() ]))

    def register(self, keyconfig):
        if isinstance(keyconfig, TPMKey):
            keyconfig = keyconfig.keyconfigfile
        keyconfigs = self.load_keyconfigs()

        if not self.calculate_path(keyconfig) in [ self.calculate_path(kc) for kc in keyconfigs ]:
            keyconfigs += [ keyconfig ]

        self.regenerate_config(keyconfigs)

    def deregister(self, keyconfig):
        if isinstance(keyconfig, TPMKey):
            keyconfig = keyconfig.keyconfigfile
        keyconfigs = self.load_keyconfigs()

        for i, v in enumerate(keyconfigs):
            if self.calculate_path(v) == self.calculate_path(keyconfig):
                del keyconfigs[i]

        self.regenerate_config(keyconfigs)

    def read_configfile(self, keep_comments=False):
        try:
            with open(self.configfile, 'r') as f:
                return self.read_settings(f.read().split('\n'), keep_comments=keep_comments)
        except IOError:
            return []

    def load_keyconfigs(self):
        return [ v for k, v in filter(lambda s: s[0] == self.KEYCONFIG_SETTING_NAME, self.read_configfile()) ]

    def regenerate_config(self, keyconfigs):
        settings = list(filter(lambda s: s[0] != self.KEYCONFIG_SETTING_NAME, self.read_configfile(keep_comments=True)))
        if len(settings) == 0 or settings[-1] != ('',):
            settings += [ ('',) ]
        settings += [ (self.KEYCONFIG_SETTING_NAME, keyconfig) for keyconfig in keyconfigs ]
        with open(self.configfile, 'w') as f:
            f.write('\n'.join([ ' '.join(s) for s in settings ]))

    def calculate_path(self, relative_path):
        return TPMKey.calculate_path(self.directory, relative_path)

    @staticmethod
    def read_settings(lines, keep_comments=False):
        return tuple([ tuple(v[0:2]) for v in filter(lambda l: keep_comments or (len(l) > 0 and l[0] != '#'), [ re.split('[ \t]+', line.rstrip(' \t\r').lstrip(' \t'), 1) for line in lines ]) ])

SoftwareKey.Store = SoftwareStore
TPMKey.Store = TPMEnhancedSoftwareStore

KeyStore = SoftwareStore if not detect_tpm() else TPMEnhancedSoftwareStore

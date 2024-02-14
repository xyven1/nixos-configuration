from base64 import b64encode
from hashlib import sha256
from os import path, urandom

SALT_LEN = 64
SECRET_LEN = 30

def hex2bytes(hex):
    hex = hex if len(hex) % 2 == 0 else '0' + hex
    return bytes([ int(hex[idx:idx+1], 16) for idx in range(0, len(hex), 2) ])

def int2bytes(i):
    return hex2bytes('%x' % i)

def generate_secret(certificate, salt=urandom(SALT_LEN)):
    input = bytes(certificate.parse().subject_key_id()) + int2bytes(int(path.getmtime(certificate.file) * 1000))
    for _ in range(1, 100):
        hash = sha256()
        hash.update(bytes('PRIVATE KEY SECRET DERIVATION'.encode('utf-8')))
        hash.update(salt)
        hash.update(input)
        salt = hash.digest()
    return b64encode(salt)[0:SECRET_LEN]

def generate_temporary_secret():
    return ''.join([ '%02x' % b for b in bytearray(urandom(int(SECRET_LEN / 2))) ])


class MetaDataPRNGSecretStorage(object):
    def __init__(self):
        pass

    def generate_private_key_secret(self, certificate):
        return self.get_private_key_secret(certificate)

    def get_private_key_secret(self, certificate):
        return generate_secret(certificate, salt=bytes())

    def delete_private_key_secret(self, certificate):
        pass


class FreeDesktopSecretStorage(object):
    def __init__(self):
        from dbusproxies import SecretsServiceProxy
        self.service = SecretsServiceProxy()

    def generate_private_key_secret(self, certificate):
        secret = generate_secret(certificate)
        hash = certificate.sha1()

        with self.service.session() as session:
            collection = self.service.default_collection(session)
            collection.set(hash, secret, account=certificate.identity())
        return secret

    def get_private_key_secret(self, certificate):
        with self.service.session() as session:
            collection = self.service.default_collection(session)
            secret = collection.get(certificate.sha1())

        if secret:
            return secret

        return MetaDataPRNGSecretStorage().get_private_key_secret(certificate)

    def delete_private_key_secret(self, certificate):
        with self.service.session() as session:
            collection = self.service.default_collection(session)
            collection.delete(certificate.sha1())

    @classmethod
    def detect(cls):
        hash = '0000000000000000000000000000000000000000'
        secret = 'test secret'

        # Prevent any error logs during detection
        import logging
        dbuslogger = logging.getLogger('dbus.connection')
        dbuslogger_previous_level = dbuslogger.level
        dbuslogger.setLevel(logging.CRITICAL)

        try:
            from dbusproxies import SecretsServiceProxy
            secrets_service = SecretsServiceProxy()
            with secrets_service.session() as session:
                collection = secrets_service.default_collection(session)
                collection.set(hash, secret)
                if collection.get(hash) != secret:
                    return False
                collection.delete(hash)
                return True
        except:
            return False
        finally:
            dbuslogger.setLevel(dbuslogger_previous_level)

SecretStorage = FreeDesktopSecretStorage() if FreeDesktopSecretStorage.detect() else MetaDataPRNGSecretStorage()


from base64 import b64encode, b64decode
from datetime import datetime
from hashlib import sha1
from os import getpid

from enrollapi import Connector, ChallengeRequest, EnrollmentRequest, PasswordAuthentication, EnrollmentException
from keystore import KeyStore, SoftwareStore, TPMEnhancedSoftwareStore, Certificate, PrivateKeyExists

class TPMRequired(EnrollmentException):
    pass

def keyprefix(credentials):
    return 'sw2-joinnow-client-cert-' + sha1(credentials.identity.encode('utf-8')).hexdigest()

def keyname(credentials):
    return keyprefix(credentials) + '_' + datetime.now().strftime('%Y%m%d-%H%M%S') + '_' + str(getpid())

def enroll(config, credentials, ui):
    ui.update_status(251)

    keystore = (KeyStore if config.bool('useTPM', default=True) else SoftwareStore)()

    if config.bool('requireTPM', default=True) and not isinstance(keystore, TPMEnhancedSoftwareStore):
        raise TPMRequired('Error during certificate enrollment: Configuration requires the use of a TPM, but TPM or required utilities not found on system')

    private_key = keystore.generate(keyname(credentials), config.int('keySize', default=2048))

    try:
        csr = b64encode(private_key.generate_csr(credentials.identity)).decode('utf-8')

        ui.update_status(252)

        connector = Connector(config['URL'])
        connector.negotiate_version()
        old_certificates = list(filter(lambda c: c.private_key.name != None and c.private_key.name.startswith(keyprefix(credentials)), keystore.certificates(with_private_key=True)))

        challenges_response = ChallengeRequest(connector, certificates=old_certificates).send()
        enrollment_response = EnrollmentRequest(connector, credentials.identity, PasswordAuthentication(credentials.password), [ csr ], generate_device_attributes(credentials.parent.reporter, credentials), old_certificates, challenges_response, generate_configinfo_attributes(credentials.parent.reporter)).send()

        if len(enrollment_response.certificates) != 1:
            raise EnrollmentException('Error during certificate enrollment: Server returned %d certificates, while 1 was expected' % len(enrollment_response.certificates))

        certificate = Certificate(enrollment_response.certificates[0], private_key=private_key)

        ui.update_status(253)

        certificate.write(keystore.certificate_path(private_key))

    except Exception as e:
        private_key.delete()
        raise

    if 'enrollAttributes' in enrollment_response.data:
        try:
            hints = enrollment_response.data['enrollAttributes']
            if hints != None and 'Revoked-Certificates' in hints:
                revoke_certificates = [ b64decode(thumbprint) for thumbprint in hints['Revoked-Certificates'] ]
                for cert in filter(lambda c: c.sha1(raw=True) in revoke_certificates, old_certificates):
                    cert.delete()
        except (TypeError, AttributeError, ValueError):
            pass

    return certificate

def generate_device_attributes(reporter, credentials):
    attributes = dict(reporter.nextgen_device_attributes())
    attributes['userDescription'] = credentials.description
    return attributes

def generate_configinfo_attributes(reporter):
    return dict(reporter.nextgen_configinfo())

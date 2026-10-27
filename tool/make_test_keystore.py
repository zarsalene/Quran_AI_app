"""Create android/app/test-signing.p12, the key that signs test builds.

Every CI build used to get a new temporary debug key, so a new APK could not
install over an older one. This fixed key solves that for test builds.

It is committed to the repo on purpose and is NOT secret. Before a public
release, sign with a private key kept in GitHub Secrets instead.

    tool/spike/.venv/Scripts/python.exe -I tool/make_test_keystore.py
"""

import datetime
import sys
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

OUT = Path(__file__).resolve().parent.parent / "android" / "app" / "test-signing.p12"
PASSWORD = b"rattil-test"
ALIAS = b"rattil"


def main() -> int:
    if OUT.exists():
        print(f"{OUT} exists; delete it first to make a new key (old installs will not update).")
        return 1
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Rattil test builds")])
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now)
        .not_valid_after(now + datetime.timedelta(days=365 * 30))
        .sign(key, hashes.SHA256())
    )
    data = pkcs12.serialize_key_and_certificates(
        ALIAS, key, cert, None, serialization.BestAvailableEncryption(PASSWORD)
    )
    OUT.write_bytes(data)
    print(f"wrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

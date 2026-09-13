"""
Unit Tests for KMS AES-256-GCM Envelope Encryption
"""

import pytest
import json
from ..security.kms_vault import KmsVault


def test_kms_envelope_encryption_roundtrip():
    vault = KmsVault(master_kek_secret="test_secret_master_key_2026_xyz")
    original_payload = {"user_id": "usr_test_123", "khasra": "KH-102", "status": "VERIFIED"}
    payload_bytes = json.dumps(original_payload).encode("utf-8")

    envelope = vault.encrypt_envelope(payload_bytes)

    # Verify all expected envelope components exist
    assert "ciphertext_b64" in envelope
    assert "auth_tag_b64" in envelope
    assert "nonce_b64" in envelope
    assert "wrapped_dek_b64" in envelope
    assert "dek_nonce_b64" in envelope
    assert envelope["key_version"] == 1

    # Verify decryption restores identical payload
    decrypted_bytes = vault.decrypt_envelope(envelope)
    decrypted_json = json.loads(decrypted_bytes.decode("utf-8"))
    assert decrypted_json == original_payload


def test_kms_unique_nonces_per_call():
    vault = KmsVault()
    data = b"identical_sensitive_payload"

    env1 = vault.encrypt_envelope(data)
    env2 = vault.encrypt_envelope(data)

    # Nonces must NEVER be repeated for the same key
    assert env1["nonce_b64"] != env2["nonce_b64"]
    assert env1["ciphertext_b64"] != env2["ciphertext_b64"]
    assert env1["dek_nonce_b64"] != env2["dek_nonce_b64"]


def test_kms_tamper_detection_fails_closed():
    vault = KmsVault()
    data = b"sensitive_government_deed_data"
    envelope = vault.encrypt_envelope(data)

    # Tamper with the ciphertext
    raw_b64 = envelope["ciphertext_b64"]
    tampered_b64 = raw_b64[:-2] + ("AA" if raw_b64[-2:] != "AA" else "BB")
    envelope["ciphertext_b64"] = tampered_b64

    # Must fail closed with an exception
    with pytest.raises(ValueError) as excinfo:
        vault.decrypt_envelope(envelope)
    assert "Decryption failed" in str(excinfo.value)

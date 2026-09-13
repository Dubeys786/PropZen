"""
PropZen Secure KMS & AES-256-GCM Envelope Encryption Vault
Implements strict authenticated envelope encryption:
 - Ephemeral 256-bit Data Encryption Key (DEK) per payload
 - 96-bit (12-byte) cryptographically unique random nonce per operation
 - 128-bit authentication tag
 - Master Key Encryption Key (KEK) wrapping
 - Automated key versioning and fail-closed decryption validation
"""

import os
import secrets
import hashlib
import base64
from typing import Dict, Any, Tuple
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


class KmsVault:
    def __init__(self, master_kek_secret: str = None, key_version: int = 1):
        raw_secret = master_kek_secret or os.getenv(
            "MASTER_KEK_SECRET", "k1_propzen_master_aes256_gcm_secret_2026_vault_key"
        )
        # Derive a 256-bit (32 bytes) master KEK using SHA-256
        self._master_kek = hashlib.sha256(raw_secret.encode("utf-8")).digest()
        self._key_version = int(os.getenv("KMS_KEY_VERSION", str(key_version)))
        self._kek_cipher = AESGCM(self._master_kek)

    @property
    def key_version(self) -> int:
        return self._key_version

    def encrypt_envelope(self, plaintext_bytes: bytes, associated_data: bytes = None) -> Dict[str, Any]:
        """
        Encrypts plaintext bytes with an ephemeral DEK and wraps the DEK with master KEK.
        Returns a dictionary containing base64-encoded envelope components.
        """
        if not isinstance(plaintext_bytes, bytes):
            if isinstance(plaintext_bytes, str):
                plaintext_bytes = plaintext_bytes.encode("utf-8")
            else:
                raise ValueError("Plaintext must be bytes or string")

        # 1. Generate ephemeral 256-bit DEK using OS CSPRNG
        dek = secrets.token_bytes(32)
        dek_cipher = AESGCM(dek)

        # 2. Generate unique 96-bit nonce for payload encryption
        payload_nonce = secrets.token_bytes(12)

        # 3. Encrypt payload with DEK using AES-256-GCM
        # AESGCM.encrypt appends the 16-byte auth tag at the end of the ciphertext
        raw_encrypted = dek_cipher.encrypt(payload_nonce, plaintext_bytes, associated_data)
        ciphertext = raw_encrypted[:-16]
        auth_tag = raw_encrypted[-16:]

        # 4. Wrap DEK with Master KEK using a separate unique nonce
        dek_nonce = secrets.token_bytes(12)
        wrapped_dek = self._kek_cipher.encrypt(dek_nonce, dek, None)

        return {
            "ciphertext_b64": base64.b64encode(ciphertext).decode("utf-8"),
            "auth_tag_b64": base64.b64encode(auth_tag).decode("utf-8"),
            "nonce_b64": base64.b64encode(payload_nonce).decode("utf-8"),
            "wrapped_dek_b64": base64.b64encode(wrapped_dek).decode("utf-8"),
            "dek_nonce_b64": base64.b64encode(dek_nonce).decode("utf-8"),
            "key_version": self._key_version,
        }

    def decrypt_envelope(self, envelope: Dict[str, Any], associated_data: bytes = None) -> bytes:
        """
        Unwraps DEK using Master KEK and decrypts ciphertext with AES-256-GCM.
        Fails closed on any tag mismatch or tampering.
        """
        try:
            ciphertext = base64.b64decode(envelope["ciphertext_b64"])
            auth_tag = base64.b64decode(envelope["auth_tag_b64"])
            payload_nonce = base64.b64decode(envelope["nonce_b64"])
            wrapped_dek = base64.b64decode(envelope["wrapped_dek_b64"])
            dek_nonce = base64.b64decode(envelope["dek_nonce_b64"])

            # 1. Unwrap DEK with Master KEK
            dek = self._kek_cipher.decrypt(dek_nonce, wrapped_dek, None)
            dek_cipher = AESGCM(dek)

            # 2. Decrypt payload (reconstruct combined ciphertext + tag for AESGCM)
            combined_ciphertext = ciphertext + auth_tag
            plaintext = dek_cipher.decrypt(payload_nonce, combined_ciphertext, associated_data)
            return plaintext
        except Exception as e:
            # Strict fail-closed
            raise ValueError(f"Decryption failed: Envelope compromised or invalid key: {e}")


# Global Singleton Instance
kms_vault = KmsVault()

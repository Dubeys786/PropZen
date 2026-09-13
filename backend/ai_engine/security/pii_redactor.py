"""
PropZen PII Redaction & Privacy Gateway
Strips and masks sensitive personal identifiers before passing data to
LangGraph, CrewAI, or external LLM models.
"""

import re
from typing import Dict, Any, Union, List


class PiiRedactor:
    # Regex Patterns for Indian & Global Identifiers
    AADHAAR_PATTERN = re.compile(r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}\b")
    PAN_PATTERN = re.compile(r"\b[A-Z]{5}[0-9]{4}[A-Z]\b", re.IGNORECASE)
    PHONE_PATTERN = re.compile(r"(?:\+91[\s-]?)?(?:[6789]\d{9})\b")
    EMAIL_PATTERN = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b")
    BANK_ACCOUNT_PATTERN = re.compile(r"\b(?:A/C|AC|Account|Acc|Number)[\s:]*(\d{9,18})\b", re.IGNORECASE)

    @classmethod
    def mask_aadhaar(cls, text: str) -> str:
        def _repl(match):
            val = match.group(0).replace(" ", "").replace("-", "")
            return f"XXXX-XXXX-{val[-4:]}"
        return cls.AADHAAR_PATTERN.sub(_repl, text)

    @classmethod
    def mask_pan(cls, text: str) -> str:
        def _repl(match):
            val = match.group(0).upper()
            return f"{val[:3]}****{val[-1]}"
        return cls.PAN_PATTERN.sub(_repl, text)

    @classmethod
    def mask_phone(cls, text: str) -> str:
        def _repl(match):
            val = re.sub(r"[^\d]", "", match.group(0))
            if len(val) >= 10:
                return f"+91 XXXXX {val[-5:]}"
            return "[REDACTED_PHONE]"
        return cls.PHONE_PATTERN.sub(_repl, text)

    @classmethod
    def mask_email(cls, text: str) -> str:
        def _repl(match):
            email = match.group(0)
            parts = email.split("@")
            user, domain = parts[0], parts[1]
            if len(user) <= 2:
                masked_user = "**"
            else:
                masked_user = f"{user[0]}***{user[-1]}"
            return f"{masked_user}@{domain}"
        return cls.EMAIL_PATTERN.sub(_repl, text)

    @classmethod
    def mask_bank_account(cls, text: str) -> str:
        def _repl(match):
            val = match.group(1)
            return f"Account: XXXXXX{val[-4:]}"
        return cls.BANK_ACCOUNT_PATTERN.sub(_repl, text)

    @classmethod
    def sanitize_text(cls, text: str) -> str:
        """Applies full multi-pass sanitization on string text."""
        if not text:
            return ""
        s = cls.mask_aadhaar(text)
        s = cls.mask_pan(s)
        s = cls.mask_phone(s)
        s = cls.mask_email(s)
        s = cls.mask_bank_account(s)
        return s

    @classmethod
    def sanitize_dict(cls, data: Union[Dict, List, Any]) -> Union[Dict, List, Any]:
        """Recursively sanitizes JSON/dict payloads."""
        if isinstance(data, dict):
            return {k: cls.sanitize_dict(v) for k, v in data.items()}
        elif isinstance(data, list):
            return [cls.sanitize_dict(item) for item in data]
        elif isinstance(data, str):
            return cls.sanitize_text(data)
        return data


# Global Singleton Instance
pii_redactor = PiiRedactor()

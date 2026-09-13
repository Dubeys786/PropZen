"""
Unit Tests for PII Redaction & Privacy Gateway
"""

from ..security.pii_redactor import pii_redactor


def test_pii_redaction_aadhaar():
    text = "Owner Aadhaar is 2345 6789 0123 for property registration."
    sanitized = pii_redactor.sanitize_text(text)
    assert "XXXX-XXXX-0123" in sanitized
    assert "2345" not in sanitized


def test_pii_redaction_pan():
    text = "Seller PAN card ABCDE1234F verified."
    sanitized = pii_redactor.sanitize_text(text)
    assert "ABC****F" in sanitized
    assert "ABCDE1234F" not in sanitized


def test_pii_redaction_phone():
    text = "Contact dealer at +91 9876543210 immediately."
    sanitized = pii_redactor.sanitize_text(text)
    assert "+91 XXXXX 43210" in sanitized
    assert "9876543210" not in sanitized


def test_pii_redaction_dict():
    data = {
        "owner_name": "Ramesh Kumar",
        "email": "ramesh.kumar@example.com",
        "nested": {
            "aadhaar": "9999-8888-7777",
            "phone": "9811223344",
        }
    }
    sanitized = pii_redactor.sanitize_dict(data)
    assert sanitized["email"] == "r***r@example.com"
    assert sanitized["nested"]["aadhaar"] == "XXXX-XXXX-7777"
    assert sanitized["nested"]["phone"] == "+91 XXXXX 23344"

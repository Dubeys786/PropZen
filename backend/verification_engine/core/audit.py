"""
Audit logging for PropZen GlobalVerificationEngine
Ensures compliance by recording lifecycle verification events without storing sensitive document content.
"""
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from .security import mask_sensitive_data

logger = logging.getLogger("verification_audit")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")


class AuditLogger:
    def log_event(
        self,
        case_id: str,
        action: str,
        actor: str = "system",
        details: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Record an audit log entry.
        Never logs full document text or raw personally identifiable tokens.
        """
        safe_details = {}
        if details:
            for k, v in details.items():
                if k in ("file_bytes", "raw_text", "ocr_raw", "aadhaar", "pan", "bank_account"):
                    safe_details[k] = "[MASKED_FOR_COMPLIANCE]"
                elif isinstance(v, str):
                    safe_details[k] = mask_sensitive_data(v)
                else:
                    safe_details[k] = v

        entry = {
            "case_id": case_id,
            "action": action,
            "actor": actor,
            "details": safe_details,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        logger.info(f"AUDIT | action={action} | case_id={case_id} | actor={actor}")
        return entry


audit_logger = AuditLogger()

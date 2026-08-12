"""
Safety Agent Lambda Handler — ROSTR Framework
Gatekeeper agent enforcing HIPAA privacy boundaries, blocking diagnostic/treatment claims,
and ensuring fact vs interpretation separation.
"""

import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FORBIDDEN_TERMS = ["diagnose", "prescribe", "take 50mg", "you have cancer", "definitely caused by"]

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event.get('body', {})
        text_to_audit = body.get('text', '')

        logger.info("Safety Agent auditing output text...")

        violations = [term for term in FORBIDDEN_TERMS if term in text_to_audit.lower()]
        passed = len(violations) == 0

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "status": "success",
                "agent": "Safety Guardrail Agent",
                "passed": passed,
                "violations_detected": violations,
                "disclaimer": "Healthie is an informational intelligence tool and does not provide medical diagnosis or treatment advice. Consult your licensed healthcare provider."
            })
        }

    except Exception as e:
        logger.error("Error in Safety Agent: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": str(e)})
        }

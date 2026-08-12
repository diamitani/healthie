"""
PAL Intake Agent Lambda Handler — ROSTR Framework
Classifies uploaded health documents (Medical Labs vs Billing EOBs) and extracts structured parameters.
"""

import json
import logging
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event.get('body', {})
        document_text = body.get('text', '')
        document_name = body.get('filename', 'document.pdf')

        logger.info("PAL Intake Agent processing document: %s", document_name)

        # Classification Logic
        is_billing = bool(re.search(r'eob|explanation of benefits|cpt|billed|deductible|claim', document_text, re.IGNORECASE))
        doc_type = 'billing' if is_billing else 'medical'

        # Textract / Marker extraction simulation
        extracted_markers = []
        if doc_type == 'medical':
            if re.search(r'wbc|white blood', document_text, re.IGNORECASE):
                extracted_markers.append({"name": "WBC (White Blood Cells)", "value": "11.8 x10E3/uL", "range": "4.5 - 11.0", "status": "HIGH", "anxiety": True})
            if re.search(r'cholesterol|ldl|lipid', document_text, re.IGNORECASE):
                extracted_markers.append({"name": "Total Cholesterol", "value": "224 mg/dL", "range": "<200", "status": "HIGH", "anxiety": True})
        else:
            extracted_markers.append({"cpt": "73721", "desc": "MRI Knee Joint w/o Contrast", "billed": "$2,450.00", "allowed": "$820.00", "balance": "$246.00"})

        response_data = {
            "status": "success",
            "agent": "PAL Intake Agent",
            "document_name": document_name,
            "document_type": doc_type,
            "npao_class": "NECESSITY",
            "extracted_markers": extracted_markers
        }

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps(response_data)
        }

    except Exception as e:
        logger.error("Error in PAL Intake Agent: %s", str(e))
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": str(e)})
        }

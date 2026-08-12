"""
AWS Cognito Pre-SignUp Lambda Trigger
Frictionless Onboarding: Auto-confirms user and auto-verifies email address on signup
so the user bypasses email confirmation codes and lands immediately into their dashboard.
"""

import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Cognito PreSignUp Trigger Event: %s", json.dumps(event))
    
    # Auto-confirm the user account
    event['response']['autoConfirmUser'] = True
    
    # Auto-verify email if present in request attributes
    if 'email' in event['request']['userAttributes']:
        event['response']['autoVerifyEmail'] = True
        
    # Auto-verify phone if present
    if 'phone_number' in event['request']['userAttributes']:
        event['response']['autoVerifyPhone'] = True

    logger.info("PreSignUp auto-confirm response prepared for user: %s", event.get('userName'))
    return event

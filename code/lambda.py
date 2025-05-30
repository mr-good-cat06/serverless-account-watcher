import boto3
import json
import os
import traceback
import logging
import urllib.request
from urllib.parse import urlencode

# Set up basic logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Simple in-memory cache to track processed events (for the duration of this Lambda execution)
processed_events = set()


def get_parameter(parameter_name, decrypt=True):
    """Get parameter from SSM Parameter Store"""
    ssm = boto3.client('ssm')
    try:
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=decrypt)
        return response['Parameter']['Value']
    except Exception as e:
        logger.error(f"Failed to get parameter {parameter_name}: {str(e)}")
        raise


def parse_event(event):
    """Parse details of CloudTrail event and return formatted message"""
    result = ""
    eventName = "UNKNOWN EVENT"
    eventDetail = event.get('detail')
    
    if eventDetail:
        eventName = eventDetail.get('eventName')
        
        try:
            # S3 events
            if eventName == "DeleteBucket":
                bucket_name = eventDetail.get('requestParameters', {}).get('bucketName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Bucket \"{bucket_name}\" was deleted by \"{user_type}\" \"{user_arn}\""
                
            elif eventName == "PutBucketPolicy":
                bucket_name = eventDetail.get('requestParameters', {}).get('bucketName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Bucket \"{bucket_name}\" policy added by \"{user_type}\" \"{user_arn}\""
                
            elif eventName == "DeleteBucketPolicy":
                bucket_name = eventDetail.get('requestParameters', {}).get('bucketName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Bucket \"{bucket_name}\" policy deleted by \"{user_type}\" \"{user_arn}\""
            
            elif eventName == "CreateBucket":
                bucket_name = eventDetail.get('requestParameters', {}).get('bucketName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Bucket \"{bucket_name}\" created by \"{user_type}\" \"{user_arn}\""
            
            
            # IAM events
            elif eventName == "CreateAccessKey":
                access_key_id = eventDetail.get('responseElements', {}).get('accessKey', {}).get('accessKeyId', 'Unknown')
                user_name = eventDetail.get('requestParameters', {}).get('userName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Access Key \"{access_key_id}\" for user \"{user_name}\" created by \"{user_type}\" \"{user_arn}\""
                
            elif eventName == "DeleteAccessKey":
                access_key_id = eventDetail.get('requestParameters', {}).get('accessKeyId', 'Unknown')
                user_name = eventDetail.get('requestParameters', {}).get('userName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Access Key \"{access_key_id}\" for user \"{user_name}\" deleted by \"{user_type}\" \"{user_arn}\""
                
            elif eventName == "UpdateRole":
                role_name = eventDetail.get('requestParameters', {}).get('roleName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Role \"{role_name}\" updated by \"{user_type}\" \"{user_arn}\""
                
            elif eventName == "DeleteRole":
                role_name = eventDetail.get('requestParameters', {}).get('roleName', 'Unknown')
                user_type = eventDetail.get('userIdentity', {}).get('type', 'Unknown')
                user_arn = eventDetail.get('userIdentity', {}).get('arn', 'Unknown')
                result = f"Role \"{role_name}\" deleted by \"{user_type}\" \"{user_arn}\""
 
            # Console Login events    
            elif eventName == "ConsoleLogin":
                source_ip = eventDetail.get('sourceIPAddress', 'Unknown')
                result = f"Root user console login from IP: \"{source_ip}\""                    
                
            # Default generic event    
            else:
                result = str(eventDetail)
                
        except KeyError as e:
            logger.warning(f"Missing expected field in event {eventName}: {str(e)}")
            result = f"Event {eventName} occurred but some details are missing"
        except Exception as e:
            logger.error(f"Error parsing event {eventName}: {str(e)}")
            result = str(event)
            
    return eventName, result


def send_slack_message(payload, webhook):
    """Send Slack message to passed in URL using urllib"""
    # Don't log the webhook URL for security
    logger.info(f"Sending Slack message with payload keys: {list(payload.keys())}")
    
    data = json.dumps(payload).encode('utf-8')
    
    req = urllib.request.Request(
        webhook,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        response = urllib.request.urlopen(req)
        logger.info(f"Slack message sent successfully. Status: {response.getcode()}")
        return response
    except urllib.request.HTTPError as e:
        logger.error(f"HTTP Error sending Slack message: {e.code} - {e.reason}")
        return e
    except Exception as e:
        logger.error(f"Request failed: {str(e)}")
        return None


def publish_to_sns(subject, message, topic):
    """Publish message to SNS topic"""
    logger.info(f"Publishing to SNS - Subject: {subject}")
    # Send message to SNS
    sns_client = boto3.client('sns')
    try:
        response = sns_client.publish(TopicArn=topic, Subject=subject, Message=message)
        logger.info(f"SNS message published successfully. MessageId: {response.get('MessageId')}")
        return response
    except Exception as e:
        logger.error(f"Failed to publish to SNS: {str(e)}")
        raise
    
    
def lambda_handler(event, context):
    try:   
        # Create a unique identifier for this event
        event_id = event.get('id', '')
        event_time = event.get('time', '')
        event_detail = event.get('detail', {})
        event_name = event_detail.get('eventName', '')
        
        # Create a unique key combining multiple fields
        unique_key = f"{event_id}_{event_time}_{event_name}"
        
        # Check if we've already processed this event
        if unique_key in processed_events:
            logger.info(f"Duplicate event detected, skipping: {unique_key}")
            return {"statusCode": 200, "body": "Duplicate event ignored"}
        
        # Mark this event as processed
        processed_events.add(unique_key)
        
        # Get sensitive values from Parameter Store
        SNS_TOPIC_ARN = get_parameter("/alerts/sns-topic-arn", decrypt=False)
        SLACK_WEBHOOK_URL = get_parameter("/alerts/slack-webhook", decrypt=True)
        
        logger.info(f"Retrieved configuration parameters successfully")

        event_name, event_detail = parse_event(event)
        slack_msg = f"{event_name}: {event_detail}"
        logger.info(f"Processed event: {event_name}")
        
        slack_response = send_slack_message({"text": slack_msg}, SLACK_WEBHOOK_URL)
        
        sns_subject = event_name
        sns_msg = event_detail
        sns_response = publish_to_sns(sns_subject, sns_msg, SNS_TOPIC_ARN)
        
        return {"statusCode": 200, "body": "Event processed successfully"}
                
    except Exception as ex:
        logger.exception("Exception hit in lambda_handler")
        raise RuntimeError("Cannot process event") from ex
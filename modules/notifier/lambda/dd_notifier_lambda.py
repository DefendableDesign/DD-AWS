#!/usr/bin/env python3
'''
This Lambda function sends notifications for changes in DD_Config_* Config Rule status.

Trigger Type: SNS Notification
'''

'''
Follow these steps to configure the webhook in Slack:
  1. Navigate to https://my.slack.com/services/new/incoming-webhook/
  2. Choose the default channel where messages will be sent and click "Add Incoming WebHooks Integration".
  3. Copy the webhook URL and supply it as the slack_webhook_url variable to terraform apply
      Terraform will automatically encrypt the url for you.
'''

import boto3
import json
import logging
import os
import dateutil.parser

from base64 import b64decode
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


# The base-64 encoded, encrypted key (CiphertextBlob) stored in the kmsEncryptedHookUrl environment variable
ENCRYPTED_HOOK_URL = os.environ["kmsEncryptedHookUrl"]
# The Slack channel to send a message to stored in the slackChannel environment variable
SLACK_CHANNEL = os.environ["slackChannel"]

HOOK_URL = boto3.client("kms").decrypt(CiphertextBlob=b64decode(ENCRYPTED_HOOK_URL))["Plaintext"].decode("utf-8")

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ALARM_SEVERITY = {
    "DD_BP_Alarm_Unauthorized_API_Calls"      : "medium",
    "DD_BP_Alarm_Console_Sign_In_Without_MFA" : "high",
    "DD_BP_Alarm_Root_Account_Usage"          : "critical",
    "DD_BP_Alarm_IAM_Policy_Changes"          : "high",
    "DD_BP_Alarm_CloudTrail_Config_Changes"   : "medium",
    "DD_BP_Alarm_Console_Sign_In_Failures"    : "medium",
    "DD_BP_Alarm_Disable_Delete_CMK"          : "info",
    "DD_BP_Alarm_S3_Bucket_Policy_Changes"    : "medium",
    "DD_BP_Alarm_AWS_Config_Changes"          : "high",
    "DD_BP_Alarm_Security_Group_Changes"      : "medium",
    "DD_BP_Alarm_NACL_Changes"                : "medium",
    "DD_BP_Alarm_Network_Gateway_Changes"     : "medium",
    "DD_BP_Alarm_Route_Table_Changes"         : "medium",
    "DD_BP_Alarm_VPC_Changes"                 : "medium"
}

SEVERITY_COLOR_ALARM = {
    "info"      : "#00c7ff",
    "low"       : "good",
    "medium"    : "warning",
    "high"      : "danger",
    "critical"  : "#6e00bc"
}

SEVERITY_COLOR_CONFIG = {
    "COMPLIANT"     : "good",
    "NON_COMPLIANT" : "danger"
}

def process_event(event):
    sns_event = event.get("Records", None)
    remediation_event = event.get("remediationSource", None)
    if sns_event:
        source = event["Records"][0]["Sns"]["TopicArn"]
        message = json.loads(event["Records"][0]["Sns"]["Message"])
        if source.endswith("DD_Config_SNS_Topic"):
            return process_config_event(message)
        elif source.endswith("DD_BP_SNS_Monitoring_Topic"):
            return process_alarm_event(message)
    elif remediation_event:
        return process_remediation_event(event)
    return None


def process_config_event(message):
    slack_message = None
    rule_name = message.get("configRuleName", None)
    if rule_name:
        old_result = message["oldEvaluationResult"]["complianceType"]
        new_result = message["newEvaluationResult"]["complianceType"]
        if old_result != new_result:
            color           = SEVERITY_COLOR_CONFIG[new_result]
            alarm_time      = dateutil.parser.parse(message["newEvaluationResult"]["resultRecordedTime"]).timestamp()
            account_id      = message["awsAccountId"]
            resource_id     = message["resourceId"]
            resource_type   = message["resourceType"]
            message_text    = "*{1}:* {2}\n{0}".format(message["newEvaluationResult"]["annotation"], resource_type, resource_id)

            slack_message = {
                "channel": SLACK_CHANNEL,
                "icon_emoji": ":shield:",
                "username": "Defendable Config",
                "attachments": [
                    {

                        "fallback": "{0}: AWS Config State Change for {1} in {2}: \n{3}".format(new_result.upper(), rule_name, account_id, message_text),
                        "color": color,
                        "title": "AWS Config State Change for {1} in {0}".format(account_id, rule_name),
                        "text": message_text,
                        "fields": [
                            {
                                "title": "Rule Name",
                                "value": rule_name.replace("DD_Config_", ""),
                                "short": "true"
                            },
                            {
                                "title": "Account ID",
                                "value": account_id,
                                "short": "true"
                            },
                            {
                                "title": "Resource Type",
                                "value": resource_type,
                                "short": "true"
                            },
                            {
                                "title": "Resource ID",
                                "value": resource_id,
                                "short": "true"
                            },
                            {
                                "title": "Message",
                                "value": message["newEvaluationResult"]["annotation"]
                            },
                            {
                                "title": "Priority",
                                "value": new_result.replace("_", " ").title(),
                                "short": "true",
                            }
                        ],
                        "ts": alarm_time
                    }
                ]
            }
    return slack_message


def process_alarm_event(message):
    slack_message = None
    new_state = message["NewStateValue"]
    if new_state == "ALARM":
        alarm_name   = message["AlarmName"]
        severity     = ALARM_SEVERITY[alarm_name]
        color        = SEVERITY_COLOR_ALARM[severity]
        alarm_time   = dateutil.parser.parse(message["StateChangeTime"]).timestamp()
        account_id   = message["AWSAccountId"]
        message_text = "{0}\n{1}".format(message["AlarmDescription"], message["NewStateReason"])

        slack_message = {
            "channel": SLACK_CHANNEL,
            "icon_emoji": ":loudspeaker:",
            "username": "Defendable Alerts",
            "attachments": [
                {

                    "fallback": "{0}: CloudTrail Alert for {1} in {2}: \n{3}".format(severity.title(), alarm_name, account_id, message_text),
                    "color": color,
                    "fields": [
                        {
                            "title": "Alarm Name",
                            "value": alarm_name.replace("DD_BP_Alarm_", ""),
							"short": "true"
                        },
						{
                            "title": "Account ID",
                            "value": account_id,
                            "short": "true"
                        },
						{
                            "title": "Description",
                            "value": message["AlarmDescription"]
                        },
						{
                            "title": "Message",
                            "value": message["NewStateReason"]
                        },
                        {
                            "title": "Priority",
                            "value": severity.title(),
                            "short": "true",
                        }
                    ],
                    "ts": alarm_time
                }
            ]
        }
    return slack_message

def process_remediation_event(event):
    slack_message = None
    severity      = "critical"
    color         = SEVERITY_COLOR_ALARM[severity]
    event_time    = dateutil.parser.parse(event["actionCompleteTime"]).timestamp()
    account_id    = event["awsAccountId"]
    message_text  = event["message"]
    resource_id   = event["resourceId"]
    resource_type = event["resourceType"]
    action        = event["action"]

    slack_message = {
        "channel": SLACK_CHANNEL,
        "icon_emoji": ":female-firefighter:",
        "username": "Defendable Automation",
        "attachments": [
            {

                "fallback": "{0}: Automated Remediation Taken on {1} ({2}) in {3}: \n{4}".format(severity.title(), resource_id, resource_type, account_id, message_text),
                "color": color,
                "fields": [
                    {
                        "title": "Automated Action",
                        "value": action,
                        "short": "true"
                    },
                    {
                        "title": "Account ID",
                        "value": account_id,
                        "short": "true"
                    },
                    {
                        "title": "Resource Type",
                        "value": resource_type,
                        "short": "true"
                    },
                    {
                        "title": "Resource ID",
                        "value": resource_id,
                        "short": "true"
                    },
                    {
                        "title": "Message",
                        "value": message_text
                    },
                    {
                        "title": "Priority",
                        "value": severity.title(),
                        "short": "true",
                    }
                ],
                "ts": event_time
            }
        ]
    }
    return slack_message

def lambda_handler(event, context):
    logger.info("Event: " + json.dumps(event))
    slack_message = process_event(event)
    logger.info("Message: " + json.dumps(slack_message))

    if slack_message:
        req = Request(HOOK_URL, json.dumps(slack_message).encode("utf-8"))
        try:
            response = urlopen(req)
            response.read()
            logger.info("Message posted to %s", slack_message["channel"])
        except HTTPError as e:
            logger.error("Request failed: %d %s", e.code, e.reason)
        except URLError as e:
            logger.error("Server connection failed: %s", e.reason)
    else:
        logger.info("Event discarded")

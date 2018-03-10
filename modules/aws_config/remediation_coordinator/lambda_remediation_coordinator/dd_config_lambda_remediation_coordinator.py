"""
This Lambda function coordinates the remediation of violations identfied by the DD_Config_* Config
Rules.

Trigger Type: Scheduled Event
Accepted Parameters: sqsUrl
Example Value: sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name"
"""

import json
import boto3

RULE_FUNCTION_MAP = {
    "EC2_SG_PROHIBITED_PORT"  : "DD_Config_Lambda_EC2_OpenPorts_Remediation",
    "S3_BUCKET_PUBLIC_ACL"    : "DD_Config_Lambda_S3_PublicAccess_Remediation",
    "S3_BUCKET_PUBLIC_POLICY" : "DD_Config_Lambda_S3_PublicAccess_Remediation"
}

def receive_messages(queue):
    """
    Receives messages from an SQS Queue.
    :param queue: boto3 SQS Queue
    :return: messages
    """
    response = queue.receive_messages(
        AttributeNames=['All'],
        MessageAttributeNames=['All'],
        MaxNumberOfMessages=10,
        VisibilityTimeout=180,
        WaitTimeSeconds=3,
    )
    return response


def call_remediation_handler(sqs_url, receipt_handle, body):
    """
    Calls the remediation Lambda function for a given violation type.
    :param sqs_url: The URL of the source SQS queue
    :param receipt_handle: The receiptHandle of the source SQS message
    :param body: The body of the source SQS message
    """
    #pylint: disable=unused-variable
    lambda_client = boto3.client('lambda')

    violation_type = body["violationType"]
    rule_handler = RULE_FUNCTION_MAP[violation_type]

    payload = {
        "sqsUrl" : sqs_url,
        "receiptHandle" : receipt_handle,
        "messageBody" : body
    }

    payload_bytes = json.dumps(payload).encode('utf-8')

    invoke_response = lambda_client.invoke(
        FunctionName=rule_handler,
        InvocationType='Event',
        Payload=payload_bytes
    )



def lambda_handler(event, context):
    """
    Lambda Function handler
    """
    #pylint: disable=unused-argument
    #pylint: disable=print-statement

    #rule_function_map = event["ruleFunctionMap"]
    
    sqs_url = event["sqsUrl"]
    sqs = boto3.resource("sqs")
    queue = sqs.Queue(sqs_url)

    processed = 0

    while True:
        messages = receive_messages(queue)

        if not messages:
            break
        for msg in messages:
            body = json.loads(msg.body)
            receipt_handle = msg.receipt_handle
            call_remediation_handler(sqs_url, receipt_handle, body)
            processed += 1

    log_message = {"action": "RemediationTriggered", "messagesProcessed": processed}
    print json.dumps(log_message)

    return True

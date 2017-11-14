#
# Trigger Type: Scheduled Event
# Accepted Parameters: sqsUrl
# Example Value: sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name"

import json
import boto3


def check_http_ok(response):
    """
    Checks for successful HTTPS 200/201 response code.
    :param response: boto3 response
    :return:
    """
    if not response["ResponseMetadata"]["HTTPStatusCode"] in (200, 201):
        err = json.dumps(response.get('Failed') or content)
        raise Exception(err)

def receive_messages(queue):
    """
    Receives messages from an SQS Queue.
    :param queue: boto3 SQS Queue
    :return: messages
    """
    response = queue.receive_message(
        AttributeNames=['All'],
        MessageAttributeNames=['All'],
        MaxNumberOfMessages=10,
        WaitTimeSeconds=5,
    )
    check_http_ok(response)
    return response.get('Messages')

def delete_messages(queue, messages):
    """
    Bulk deletes messages from an SQS Queue.
    :param queue: boto3 SQS Queue
    :param messages: boto3 Messages from receive_messages
    :return:
    """
    entries = [
        {'Id': msg['MessageId'], 'ReceiptHandle': msg['ReceiptHandle']}
        for msg in messages
    ]
    response = queue.delete_message_batch(
        Entries=entries
    )
    check_http_ok(response)

def remediate_violation(security_group, ip_permissions):
    """
    Deletes the violating security group ip_permissions item detected by AWS Config
    :param security_group: The name of the security group to operate on
    :param ip_permissions: The ip_permissions object detected by AWS Config
    :return:
    """
    ec2 = boto3.resource('ec2')
    sg = ec2.SecurityGroup(security_group)

    response = sg.revoke_ingress(
        IpPermissions=ip_permissions
        DryRun=False
    )

def lambda_handler(event, context):
    sqs_url = json.loads(event["sqsUrl"])
    sqs = boto3.resource("sqs")
    queue = sqs.Queue(sqs_url)
    
    try:
        while true
            messages = receive_messages(queue)
            
            if messages is None:
                break

            for msg in messages:
                remediate_violation(msg.get("security_group"), msg.get("ip_permission"))
            delete_messages(msgs)
    except Exception as e:
        return False
    else:
        return True
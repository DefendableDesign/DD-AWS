"""
This Lambda function remediates violations identfied by the DD_Config_EC2_OpenPorts Config Rule.

Trigger Type: Scheduled Event
Accepted Parameters: sqsUrl
Example Value: sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name"
"""
#pylint: disable=print-statement
import json
import boto3
import botocore
import os
import datetime

NOTIFIER_ENABLED = os.environ["notifierEnabled"]
NOTIFIER_FUNCTION = os.environ["notifierFnName"]

def remediate_violation(group_id, ip_permission):
    """
    Deletes the violating security group rules detected by AWS Config.
    :param group_id: The groupId of the offending SecurityGroup
    :param ip_permission: IpPermission containing violating rules to be revoked
    """
    ec2 = boto3.resource('ec2')
    sec_grp = ec2.SecurityGroup(group_id)

    ip_permission = deserialize_ippermission(ip_permission)

    log_message = {"action": "RevokeSecurityGroupIngress",
                   "groupId": group_id, "ipPermission": ip_permission}
    print json.dumps(log_message)

    try:
        sec_grp.revoke_ingress(
            IpPermissions=[ip_permission],
            DryRun=False
        )
    except botocore.exceptions.ClientError as client_error:
        if client_error.response['Error']['Code'] == 'InvalidPermission.NotFound':
            # If the offending security group entry no longer exists, do nothing.
            log_message = {
                "action": "OperationAborted", 
                "attemptedAction": "RevokeSecurityGroupIngress", 
                "groupId": group_id, 
                "message": "The offending security group no longer exists."}
            print json.dumps(log_message)
        else:
            log_message = {
                "action": "Error", 
                "attemptedAction": "RevokeSecurityGroupIngress", 
                "groupId": group_id, 
                "accessControlPolicy": "Unexpected error: {0}".format(client_error)}
            print json.dumps(log_message)
            return False, log_message
    return True, log_message

def notify(log_message, source, account_id):
    """
    Calls the Notifier Lambda function to notify slack that action has been taken.
    :param log_message: The log message string
    """
    #pylint: disable=unused-variable
    print("Running notifier: {0}".format(NOTIFIER_FUNCTION))
    lambda_client = boto3.client('lambda')

    payload = {
        "remediationSource" : source,
        "resourceId" : log_message["groupId"],
        "resourceType" : "AWS::EC2::SecurityGroup",
        "action" : log_message["action"],
        "actionCompleteTime" : datetime.datetime.utcnow().isoformat() + "+00:00",
        "awsAccountId" : account_id,
        "message" : "The following entry was removed from {0}:\n```\n{1}\n```".format(log_message["groupId"], json.dumps(log_message["ipPermission"], indent=4, sort_keys=True))
    }

    payload_bytes = json.dumps(payload).encode('utf-8')

    invoke_response = lambda_client.invoke(
        FunctionName=NOTIFIER_FUNCTION,
        InvocationType='Event',
        Payload=payload_bytes
    )
    
    return True

def dequeue_message(sqs_url, receipt_handle):
    """
    Deletes a message from the specified SQS queue.
    :param sqs_url: The url for the SQS queue
    :param receipt_handle: The ReceiptHandle for the SQS message to delete
    """
    client = boto3.client('sqs')

    client.delete_message(
        QueueUrl=sqs_url,
        ReceiptHandle=receipt_handle
    )


def upperfirst(input_string):
    """
    Capitalises the first letter only in a string.
    :param input_string: The string to operate on
    """
    return input_string[0].upper() + input_string[1:]


def deserialize_ippermission(json_ipp):
    """
    Recursively deserializes an AWS IpPermission JSON object as a boto3 compatible dict.
    :param json_ipp: A string containing the AWS Config-native representation of an IpPermission
    :return: Returns a boto3 compatible dict representing an IpPermission
    """
    boto_ipp = {}
    if not isinstance(json_ipp, basestring):
        for key in json_ipp:
            val = json_ipp[key]
            if isinstance(val, list):
                new_val = []
                for list_item in val:
                    new_val.append(deserialize_ippermission(list_item))
            elif isinstance(val, dict):
                new_val = deserialize_ippermission(val)
            else:
                new_val = val

            if key == "ipv4Ranges":
                boto_ipp["IpRanges"] = new_val
            elif key == "ipRanges":
                pass
            else:
                boto_ipp[upperfirst(key)] = new_val
        return boto_ipp

    return json_ipp


def lambda_handler(event, context):
    """
    Lambda Function handler
    """
    #pylint: disable=unused-argument

    sqs_url = event["sqsUrl"]
    receipt_handle = event["receiptHandle"]
    body = event["messageBody"]
    group_id = body["targetResourceId"]
    ip_permission = body["violationDetails"]

    success = False
    result = remediate_violation(group_id, ip_permission)
    success = result[0]
    message = result[1]

    if success:
        dequeue_message(sqs_url, receipt_handle)
        if NOTIFIER_ENABLED == "true":
            if message["action"] == "RevokeSecurityGroupIngress":
                fn_name = context.function_name
                account_id = context.invoked_function_arn.split(":")[4]
                notify(message, fn_name, account_id)

    return True

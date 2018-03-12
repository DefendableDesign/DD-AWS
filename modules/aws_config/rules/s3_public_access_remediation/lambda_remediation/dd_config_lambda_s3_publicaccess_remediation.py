"""
This Lambda function remediates violations identfied by the DD_Config_S3_PublicAccess Config Rule.

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

def remediate_violation_acl(bucket_name):
    """
    Deletes any ACL which grants permissions to AllUsers or AuthenticatedUsers.
    :param bucket_name: The BucketName of the offending S3 Bucket
    """
    #pylint: disable=unused-variable
    s3 = boto3.resource('s3')
    bucket_acl = s3.BucketAcl(bucket_name)

    grants = bucket_acl.grants

    for grant in grants:
        if grant["Grantee"]["Type"] == "Group":
            if grant["Grantee"]["URI"] in ["http://acs.amazonaws.com/groups/global/AllUsers", "http://acs.amazonaws.com/groups/global/AllAuthenticatedUsers"]:
                print("Identified AllUsers or AllAuthenticatedUsers, removing grant.")
                grants.remove(grant)

    acp = {
        'Grants': grants,
        'Owner': bucket_acl.owner
    }
    try:
        response = bucket_acl.put(
            AccessControlPolicy = acp
        )
        log_message = {"action": "PutBucketAcl", "bucketName": bucket_name, "accessControlPolicy": json.dumps(acp)}
        print json.dumps(log_message)
    except botocore.exceptions.ClientError as client_error:
        if client_error.response['Error']['Code'] == 'OperationAborted':
            log_message = {
                "action": "OperationAborted", 
                "attemptedAction": "PutBucketAcl", 
                "bucketName": bucket_name, 
                "message": "{0}".format(client_error.response['Error']['Message'])}
            print json.dumps(log_message)
        else:
            log_message = {
                "action": "Error", 
                "attemptedAction": "PutBucketAcl", 
                "bucketName": bucket_name, 
                "accessControlPolicy": "Unexpected error: {0}".format(client_error)}
            print json.dumps(log_message)
        return False, log_message
    return True, log_message


def remediate_violation_policy(bucket_name):
    """
    Deletes any S3 bucket policy statement which has effect Allow for the Principal *.
    :param bucket_name: The BucketName of the offending S3 Bucket
    """
    #pylint: disable=unused-variable
    s3 = boto3.resource('s3')
    bucket_policy = s3.BucketPolicy(bucket_name)

    policy = json.loads(bucket_policy.policy)

    for statement in policy["Statement"]:
        if statement["Effect"] == "Allow":
            if statement["Principal"] == "*":
                print("Identified * Principal in Allow statement, removing statement.")
                policy["Statement"].remove(statement)
    try:            
        response = bucket_policy.put(
            ConfirmRemoveSelfBucketAccess=False,
            Policy = json.dumps(policy)
        )
        log_message = {"action": "PutBucketPolicy", "bucketName": bucket_name, "bucketPolicy": json.dumps(policy)}
        print json.dumps(log_message)
    except botocore.exceptions.ClientError as client_error:
        if client_error.response['Error']['Code'] == 'OperationAborted':
            log_message = {
                "action": "OperationAborted", 
                "attemptedAction": "PutBucketPolicy", 
                "bucketName": bucket_name, 
                "message": "{0}".format(client_error.response['Error']['Message'])}
            print json.dumps(log_message)
        else:
            log_message = {
                "action": "Error", 
                "attemptedAction": "PutBucketPolicy", 
                "bucketName": bucket_name, 
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
    lambda_client = boto3.client('lambda')

    message = ""
    if log_message["action"] == "PutBucketPolicy":
        template = "A \"*\" Principal in an Allow policy statement was fixed by applying an updated bucket policy to {0}:\n```\n{1}\n```"
        bucket_policy = json.loads(log_message["bucketPolicy"])
        bucket_policy = json.dumps(bucket_policy, indent=4, sort_keys=True)
        message = template.format(log_message["bucketName"], bucket_policy)
    elif log_message["action"] == "PutBucketAcl":
        template = "An AllUsers or AllAuthenticatedUsers grant was fixed by applying an updated access control policy to {0}:\n```\n{1}\n```"
        acp = json.loads(log_message["accessControlPolicy"])
        acp = json.dumps(acp, indent=4, sort_keys=True)
        message = template.format(log_message["bucketName"], acp)

    payload = {
        "remediationSource" : source,
        "resourceId" : log_message["bucketName"],
        "resourceType" : "AWS::S3::Bucket",
        "action" : log_message["action"],
        "actionCompleteTime" : datetime.datetime.utcnow().isoformat() + "+00:00",
        "awsAccountId" : account_id,
        "message" : message
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


def lambda_handler(event, context):
    """
    Lambda Function handler
    """
    #pylint: disable=unused-argument

    sqs_url = event["sqsUrl"]
    receipt_handle = event["receiptHandle"]
    body = event["messageBody"]
    bucket_name = body["targetResourceId"]
    violation_type = body["violationType"]

    success = False
    if violation_type == "S3_BUCKET_PUBLIC_ACL":
        result = remediate_violation_acl(bucket_name)
    elif violation_type == "S3_BUCKET_PUBLIC_POLICY":
        result = remediate_violation_policy(bucket_name)

    success = result[0]
    message = result[1]

    if success:
        dequeue_message(sqs_url, receipt_handle)
        if NOTIFIER_ENABLED == "true":
            if (message["action"] == "PutBucketPolicy" or message["action"] == "PutBucketAcl"):
                fn_name = context.function_name
                account_id = context.invoked_function_arn.split(":")[4]
                notify(message, fn_name, account_id)

    return True

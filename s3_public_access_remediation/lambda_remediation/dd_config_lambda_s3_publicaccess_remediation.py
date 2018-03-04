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

    response = bucket_acl.put(
        AccessControlPolicy = acp
    )

    log_message = {"action": "PutBucketAcl",
                   "bucketName": bucket_name, "accessControlPolicy": json.dumps(acp)}

    print json.dumps(log_message)


def remediate_violation_policy(bucket_name):
    """
    Deletes any S3 bucket policy statement which has effect Allow for the Principal *.
    :param bucket_name: The BucketName of the offending S3 Bucket
    """
    #pylint: disable=unused-variable
    s3 = boto3.resource('s3')
    bucket_policy = s3.BucketPolicy('ddaws-knownpublicbucket1')

    policy = json.loads(bucket_policy.policy)

    for statement in policy["Statement"]:
        if statement["Effect"] == "Allow":
            if statement["Principal"] == "*":
                print("Identified * Principal in Allow statement, removing statement.")
                policy["Statement"].remove(statement)
                
    response = bucket_policy.put(
        ConfirmRemoveSelfBucketAccess=False,
        Policy = json.dumps(policy)
    )

    log_message = {"action": "PutBucketPolicy",
                   "bucketName": bucket_name, "bucketPolicy": json.dumps(policy)}

    print json.dumps(log_message)


def dequeue_message(sqs_url, receipt_handle):
    """
    Deletes a message from the specified SQS queue.
    :param sqs_url: The url for the SQS queue
    :param receipt_handle: The ReceiptHandle for the SQS message to delete
    """
    sqs = boto3.resource("sqs")
    sqs.delete_message(
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
    violation_type = body["violation_type"]

    if violation_type == "S3_BUCKET_PUBLIC_ACL":
        remediate_violation_acl(bucket_name)
    elif violation_type == "S3_BUCKET_PUBLIC_POLICY":
        remediate_violation_policy(bucket_name)

    dequeue_message(sqs_url, receipt_handle)

    log_message = {"action": "RemediationComplete", "bucketName": bucket_name}
    print json.dumps(log_message)

    return True
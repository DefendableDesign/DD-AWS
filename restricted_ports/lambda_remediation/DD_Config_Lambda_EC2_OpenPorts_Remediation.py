#
# This Lambda function remediates violations identfied by the DD_Config_EC2_OpenPorts the DD_Config_Queue_EC2_OpenPorts_Remediation SQS queue.
#
# Trigger Type: Scheduled Event
# Accepted Parameters: sqsUrl
# Example Value: sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name"

import json
import boto3
import botocore

def receive_messages(queue):
    """
    Receives messages from an SQS Queue.
    :param queue: boto3 SQS Queue
    :return: messages
    """
    response = queue.receive_messages(
        AttributeNames=['All'],
        MessageAttributeNames=['All'],
        MaxNumberOfMessages=5,
        WaitTimeSeconds=3,
    )
    return response


def remediate_violation(security_group, ip_permission):
    """
    Deletes the violating security group rules detected by AWS Config.
    :param security_group: The groupId of the offending SecurityGroup
    :param ip_permission: IpPermission containing violating rules to be revoked
    """
    ec2 = boto3.resource('ec2')
    sg = ec2.SecurityGroup(security_group)

    ip_permission = deserialize_ippermission(ip_permission)

    log_message = {"action" : "RevokeSecurityGroupIngress", "groupId" : security_group, "ipPermission" : ip_permission}
    print(json.dumps(log_message))

    try:
        response = sg.revoke_ingress(
            IpPermissions=[ip_permission],
            DryRun=False
        )
    except botocore.exceptions.ClientError as e:
        if e.response.get("Error", {}).get("Code") == "InvalidPermission.NotFound":
            pass # If the offending security group entry no longer exists, do nothing.
        else:
            raise e


def upperfirst(x):
    """
    Capitalises the first letter only in a string.
    :param x: The string to operate on
    """
    return x[0].upper() + x[1:]


def deserialize_ippermission(json_ipp):
    """
    Recursively deserializes an AWS IpPermission JSON object as a boto3 compatible dict.
    :param json_ipp: A string containing the AWS Config-native representation of an IpPermission
    :return: Returns a boto3 compatible dict representing an IpPermission
    """
    boto_ipp = {}
    if not isinstance(json_ipp, basestring):
        for k in json_ipp:
            v = json_ipp[k]
            if type(v) is list:
                nv = []
                for li in v:
                    nv.append(deserialize_ippermission(li))
            elif type(v) is dict:
                nv = deserialize_ippermission(v)
            else:
                nv = v

            if k == "ipv4Ranges":
                boto_ipp["IpRanges"] = nv
            elif k == "ipRanges":
                pass
            else:
                boto_ipp[upperfirst(k)] = nv
        return boto_ipp
    else:
        return json_ipp


def lambda_handler(event, context):
    sqs_url = event["sqsUrl"]
    sqs = boto3.resource("sqs")
    queue = sqs.Queue(sqs_url)

    processed = 0

    while True:
        messages = receive_messages(queue)

        if len(messages) == 0:
            break
        for msg in messages:
            body = json.loads(msg.body)
            remediate_violation(body.get("groupId"),
                                body.get("ipPermission"))
            msg.delete()
            processed += 1

    log_message = {"action" : "RemediationComplete", "messagesProcessed" : processed}
    print(json.dumps(log_message))

    return True

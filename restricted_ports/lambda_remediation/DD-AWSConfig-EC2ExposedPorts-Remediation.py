#
# Trigger Type: Scheduled Event
# Accepted Parameters: sqsUrl
# Example Value: sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name"

import json
import boto3


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
        WaitTimeSeconds=5,
    )
    return response

def remediate_violation(security_group, ip_permissions):
    """
    Deletes the violating security group ip_permissions item detected by AWS Config
    :param security_group: The name of the security group to operate on
    :param ip_permissions: The ip_permissions object detected by AWS Config
    :return:
    """
    ec2 = boto3.resource('ec2')
    sg = ec2.SecurityGroup(security_group)

    ip_permissions = reformat_aws_to_boto(ip_permissions)

    print("Revoking ingress")
    print(security_group)
    print(ip_permissions)

    try:
        response = sg.revoke_ingress(
            IpPermissions=[ip_permissions],
            DryRun=False
        )
    except Exception as e:
        print e
    else:
        return True


def upperfirst(x):
    return x[0].upper() + x[1:]


def reformat_aws_to_boto(af):
    """
    Recursive nightmare that turns the AWS-native JSON representation of an ipPermission to a boto3-friendly dict
    """
    bf = {}
    if not isinstance(af, basestring):
        for k in af:
            v = af[k]
            if type(v) is list:
                nv = []
                for li in v:
                    nv.append(reformat_aws_to_boto(li))
            elif type(v) is dict:
                nv = reformat_aws_to_boto(v)
            else:
                nv = v

            if k == "ipv4Ranges":
                bf["IpRanges"] = nv
            elif k == "ipRanges":
                pass
            else:
                bf[upperfirst(k)] = nv
        return bf
    else:
        return af


def lambda_handler(event, context):
    sqs_url = event["sqsUrl"]
    sqs = boto3.resource("sqs")
    queue = sqs.Queue(sqs_url)

    reverted = 0

    while True:
        messages = receive_messages(queue)

        if len(messages) == 0:
            break
        for msg in messages:
            body = json.loads(msg.body)
            remediate_violation(body.get("security_group"),
                                body.get("ip_permission"))
            msg.delete()
            reverted += 1

    print("{} ip permissions revoked.".format(reverted))
    return True

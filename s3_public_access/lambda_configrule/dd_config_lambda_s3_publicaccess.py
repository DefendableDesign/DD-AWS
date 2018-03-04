"""
Adapted from https://github.com/awslabs/aws-config-rules/blob/master/python/s3-exposed-bucket.py

This AWS Config Rule raises NOT_COMPLIANT for S3 buckets that expose allow public read or write.
Supplying an optional SQS Url will queue events for remediation by the
DD_Config_Lambda_S3_PublicAccess_Remediation Lambda function.

Trigger Type: Change Triggered
Scope of Changes: S3:Bucket
Accepted Parameters: sqsUrl [OPTIONAL], bucketWhitelist
Example Value:
    sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name",
    bucketWhitelist:"ddaws-knownpublicbucket1, ddaws-knownpublicbucket2"
"""

import json
import boto3

APPLICABLE_RESOURCES = ["AWS::S3::Bucket"]

def find_violations(bucket_acl, bucket_policy):
    '''
    Identifies Bucket ACL or Policy that allows unrestricted access.

    :param bucket_acl: the ACL of the bucket under evaluation
    :param bucket_policy: the Policy of the bucket under evaluation
    :param bucket_whitelist: list of whitelisted buckets
    :return: Returns list of violations
    '''
    violations = []

    bucket_acl = json.loads(bucket_acl)
    for grant in bucket_acl["grantList"]:
        if "AllUsers" in str(grant.get("grantee")) or \
            "AuthenticatedUsers" in str(grant.get("grantee")):
            violation = {
                "violation_type": "S3_BUCKET_PUBLIC_ACL",
                "details": grant
                }
            violations.append(violation)

    if bucket_policy['policyText'] is not None:
        policy = json.loads(bucket_policy['policyText'])
        for stmt in policy["Statement"]:
            if stmt["Effect"] == "Allow" and stmt["Principal"] == "*":
                violation = {
                    "violation_type": "S3_BUCKET_PUBLIC_POLICY",
                    "details": stmt
                    }
                violations.append(violation)

    return violations


def evaluate_compliance(configuration_item, bucket_whitelist):
    '''
    Evaluates each bucket in config item for violations.

    :param configuration_item: AWS Config ConfigurationItem
    :param bucket_whitelist: list of known and allowed public buckets
    :return: dict containing compliance status
    '''
    if configuration_item["resourceType"] not in APPLICABLE_RESOURCES:
        return {
            "compliance_type": "NOT_APPLICABLE",
            "annotation": "The rule doesn't apply to resources of type " +
                          configuration_item["resourceType"] + "."
        }

    if configuration_item['configurationItemStatus'] == "ResourceDeleted":
        return {
            "compliance_type": "NOT_APPLICABLE",
            "annotation": "The configurationItem was deleted " +
                          "and therefore cannot be validated."
        }

    if configuration_item['resourceId'] in bucket_whitelist:
        return {
            "compliance_type": "COMPLIANT",
            "annotation": "This resource is whitelisted."
        }

    bucket_acl = configuration_item["supplementaryConfiguration"].get("AccessControlList")
    bucket_policy = configuration_item["supplementaryConfiguration"].get("BucketPolicy")

    violations = find_violations(bucket_acl, bucket_policy)

    violation_count = len(violations)
    if violation_count > 0:
        annotation = "A configuration ({0}) allows dangerous access to this bucket.".format(
            ', '.join([v['violation_type'] for v in violations]))
        return {
            "compliance_type": "NON_COMPLIANT",
            "annotation": annotation,
            "violations": violations
        }
    return {
        "compliance_type": "COMPLIANT",
        "annotation": "This resource is compliant with the rule."
    }


def queue_violation(sqs_url, rule_name, configuration_item, violation):
    '''
    Writes a violation to the DD remediation queue.

    :param sqs_url: The url of the SQS Queue where remedition tasks are queued
    :param configuration_item: The violating configurationItem
    :param violation: Details of the violation
    '''
    sqs = boto3.resource("sqs")
    queue = sqs.Queue(sqs_url)

    message = {
        "raisedByRule": rule_name,
        "targetResourceType": configuration_item["resourceType"],
        "targetResourceId": configuration_item["resourceId"],
        "awsRegion": configuration_item["awsRegion"],
        "violationType": violation["violation_type"],
        "violationDetails": violation["details"]
        }
    queue.send_message(
        MessageBody=json.dumps(message)
    )


def lambda_handler(event, context):
    """
    Lambda Function handler
    """
    #pylint: disable=unused-argument
    #pylint: disable=print-statement

    invoking_event = json.loads(event["invokingEvent"])
    configuration_item = invoking_event["configurationItem"]
    rule_name = event["configRuleName"]
    rule_parameters = json.loads(event["ruleParameters"])

    bucket_whitelist = rule_parameters.get("bucketWhitelist")
    if bucket_whitelist:
        bucket_whitelist = [int(x.strip()) for x in bucket_whitelist.split(',')]
    sqs_url = rule_parameters.get("sqsUrl")

    result_token = "No token found."
    if "resultToken" in event:
        result_token = event["resultToken"]

    evaluation = evaluate_compliance(configuration_item, bucket_whitelist)

    if sqs_url:
        if "violations" in evaluation:
            for violation in evaluation["violations"]:
                queue_violation(sqs_url, rule_name, configuration_item, violation)

    config = boto3.client("config")
    config.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType":
                    configuration_item["resourceType"],
                "ComplianceResourceId":
                    configuration_item["resourceId"],
                "ComplianceType":
                    evaluation["compliance_type"],
                "Annotation":
                    evaluation["annotation"],
                "OrderingTimestamp":
                    configuration_item["configurationItemCaptureTime"]
            },
        ],
        ResultToken=result_token
    )

    log_message = {
        "action":
            "EvaluationComplete",
        "resourceType":
            configuration_item["resourceType"],
        "resourceId":
            configuration_item["resourceId"],
        "evaluationResult":
            evaluation
    }
    print json.dumps(log_message)

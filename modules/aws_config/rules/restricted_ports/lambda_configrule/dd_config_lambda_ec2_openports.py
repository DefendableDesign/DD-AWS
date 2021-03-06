"""
Adapted from https://github.com/awslabs/aws-config-rules/blob/master/python/ec2-exposed-group.py

This AWS Config Rule raises NOT_COMPLIANT for Security Groups that expose prohibited ports to the
internet.
Supplying an optional SQS Url will queue events for remediation by the
DD_Config_Lambda_EC2_OpenPorts_Remediation Lambda function.

Trigger Type: Change Triggered
Scope of Changes: EC2:SecurityGroup
Accepted Parameters: sqsUrl [OPTIONAL], prohibitedPorts
Example Value:
    sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name",
    prohibitedPorts:"22,3389,3306"
"""

import json
import boto3

APPLICABLE_RESOURCES = ["AWS::EC2::SecurityGroup"]


def find_violations(ip_permissions, prohibited_ports):
    '''
    Identifies IpPermission objects that allow access on prohibited ports.

    :param ip_permissions: list of IpPermission objects from the changed ConfigurationItem
    :param prohibited_ports: list of prohibited ports
    :return: Returns list of violating IpPermission objects
    '''
    invalid_ports = []
    violations = []

    for ip_permission in ip_permissions or []:
        exposed_ports = []
        ip_permission = strip_valid_cidrs(ip_permission)
        if has_invalid_cidrs(ip_permission):
            if "fromPort" in ip_permission:
                exposed_ports.extend(
                    range(ip_permission["fromPort"], ip_permission["toPort"] + 1))
            else:
                exposed_ports.extend(range(0, 65535 + 1))

            for port in prohibited_ports:
                if port in exposed_ports:
                    invalid_ports.append(port)
            
            if len(invalid_ports) > 0:
                violation = {
                    "violation_type": "EC2_SG_PROHIBITED_PORT",
                    "details": ip_permission
                }
                violations.append(violation)

    return invalid_ports, violations


def has_invalid_cidrs(ip_permission):
    '''
    Returns true if any ranges in the IpPermission match 0.0.0.0/0 or ::/0

    :param ip_permission: IpPermission object
    :return: bool True if invalid CIDRs found
    '''
    for ip_range in ip_permission["ipv4Ranges"]:
        if ip_range["cidrIp"] == "0.0.0.0/0":
            return True

    for ip_range in ip_permission["ipv6Ranges"]:
        if ip_range["cidrIpv6"] == "::/0":
            return True

    for ip_range in ip_permission["ipRanges"]:
        if ip_range == "0.0.0.0/0":
            return True

    return False


def strip_valid_cidrs(ip_permission):
    '''
    Removes any ranges from the IpPermission that are not 0.0.0.0/0 or ::/0 as
    these are not violations and should be ignored.

    :param ip_permission: IpPermission object
    :return: IpPermission object containing only violating ranges
    '''
    new_ipv4ranges = []
    new_ipv6ranges = []
    new_ranges = []

    for ip_range in ip_permission["ipv4Ranges"]:
        if ip_range["cidrIp"] == "0.0.0.0/0":
            new_ipv4ranges.append(ip_range)
    ip_permission["ipv4Ranges"] = new_ipv4ranges

    for ip_range in ip_permission["ipv6Ranges"]:
        if ip_range["cidrIpv6"] == "::/0":
            new_ipv6ranges.append(ip_range)
    ip_permission["ipv6Ranges"] = new_ipv6ranges

    for ip_range in ip_permission["ipRanges"]:
        if ip_range == "0.0.0.0/0":
            new_ranges.append(ip_range)
    ip_permission["ipRanges"] = new_ranges

    return ip_permission


def evaluate_compliance(configuration_item, prohibited_ports):
    '''
    Evaluates each ipPermssion in config item for violations.

    :param configuration_item: AWS Config ConfigurationItem
    :param prohibited_ports: list of prohibited ports
    :return: dict containing compliance status
    '''
    if configuration_item["resourceType"] not in APPLICABLE_RESOURCES:
        return {
            "compliance_type": "NOT_APPLICABLE",
            "annotation": "The rule doesn't apply to resources of type " +
                          configuration_item["resourceType"] + "."
        }

    violations = find_violations(
        configuration_item["configuration"].get("ipPermissions"),
        prohibited_ports
    )

    violation_count = len(violations[0])
    if violation_count > 0:
        annotation = "A forbidden port ({0}) is exposed to the internet.".format(
            ', '.join(str(x) for x in violations[0]))
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
    :param sg_id: The groupId of the offending SecurityGroup
    :param ip_permission: IpPermission containing violating rules to be revoked
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

    prohibited_ports = [int(x.strip())
                        for x in rule_parameters["prohibitedPorts"].split(',')]
    sqs_url = rule_parameters.get("sqsUrl")

    result_token = "No token found."
    if "resultToken" in event:
        result_token = event["resultToken"]

    evaluation = evaluate_compliance(configuration_item, prohibited_ports)

    if sqs_url:
        if "violations" in evaluation:
            violations = evaluation["violations"][1]
            for violation in violations:
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

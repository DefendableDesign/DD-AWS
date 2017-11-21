#
# Adapted from https://github.com/awslabs/aws-config-rules/blob/master/python/ec2-exposed-group.py
#
# Trigger Type: Change Triggered
# Scope of Changes: EC2:SecurityGroup
# Accepted Parameters: sqsUrl [OPTIONAL], prohibitedPorts
# Example Value: sqsUrl:"https://sqs.ap-southeast-2.amazonaws.com/0123456789/queue-name", prohibitedPorts:"22,3389,3306"


import json
import boto3

APPLICABLE_RESOURCES = ["AWS::EC2::SecurityGroup"]


def find_violations(ip_permissions, prohibited_ports):
    violations = []
    violations_permissions = []

    for ip_permission in ip_permissions or []:
        #print(json.dumps({"action": "Debug", "function": "find_violations", "ipPermission": ip_permission}))
        exposed_ports = []
        if has_invalid_cidrs(ip_permission):
            exposed_ports.extend(
                range(ip_permission["fromPort"], ip_permission["toPort"] + 1))
        for port in prohibited_ports:
            if port in exposed_ports:
                violations.append(port)
                violations_permissions.append(strip_valid_cidrs(ip_permission))

    return violations, violations_permissions


def has_invalid_cidrs(ip_permission):
    '''
    Returns true if any ranges in the ipPermission match 0.0.0.0/0 or ::/0
    '''
    for range in ip_permission["ipv4Ranges"]:
        if range["cidrIp"] == "0.0.0.0/0":
            return True

    for range in ip_permission["ipv6Ranges"]:
        if range["cidrIpv6"] == "::/0":
            return True

    for range in ip_permission["ipRanges"]:
        if range == "0.0.0.0/0":
            return True

    return False


def strip_valid_cidrs(ip_permission):
    '''
    Removes any ranges from the ipPermission that are not 0.0.0.0/0 or ::/0 as 
    these are not violations and should be ignored.
    '''
    new_ipv4ranges = []
    new_ipv6ranges = []
    new_ranges = []

    for range in ip_permission["ipv4Ranges"]:
        if range["cidrIp"] == "0.0.0.0/0":
            new_ipv4ranges.append(range)
    ip_permission["ipv4Ranges"] = new_ipv4ranges

    for range in ip_permission["ipv6Ranges"]:
        if range["cidrIpv6"] == "::/0":
            new_ipv6ranges.append(range)
    ip_permission["ipv6Ranges"] = new_ipv6ranges

    for range in ip_permission["ipRanges"]:
        if range == "0.0.0.0/0":
            new_ranges.append(range)
    ip_permission["ipRanges"] = new_ranges

    return ip_permission


def evaluate_compliance(configuration_item, prohibited_ports):
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

    if len(violations[0]) > 0:
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


def queue_violation(sqs_url, sg_id, ip_permission):
    sqs = boto3.resource("sqs")
    queue = sqs.Queue(sqs_url)
    message = {"security_group": sg_id, "ip_permission": ip_permission}
    response = queue.send_message(
        MessageBody=json.dumps(message)
    )


def lambda_handler(event, context):
    invoking_event = json.loads(event["invokingEvent"])
    configuration_item = invoking_event["configurationItem"]
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
            for v in evaluation["violations"][1]:
                queue_violation(
                    sqs_url, configuration_item["configuration"].get("groupId"), v)

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
    print(json.dumps(log_message))

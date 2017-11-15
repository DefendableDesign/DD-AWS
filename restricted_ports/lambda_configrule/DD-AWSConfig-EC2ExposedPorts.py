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
    
    for permission in ip_permissions or []:
        exposed_ports = []
        for ip in permission["ipRanges"]:
            if "0.0.0.0/0" in ip:
                exposed_ports.extend(range(permission["fromPort"], permission["toPort"]+1))
        for port in prohibited_ports:
            if port in exposed_ports:
                violations.append(port)
                violations_permissions.append(permission)

    return violations, violations_permissions


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
        annotation = "A forbidden port ({0}) is exposed to the internet.".format(', '.join(str(x) for x in violations[0]))
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
    message = {"security_group" : sg_id, "ip_permission" : ip_permission}
    response = queue.send_message(
        MessageBody=json.dumps(message)
    )
    print(response)


def lambda_handler(event, context):
    invoking_event = json.loads(event["invokingEvent"])
    configuration_item = invoking_event["configurationItem"]
    rule_parameters = json.loads(event["ruleParameters"])

    prohibited_ports = [int(x.strip()) for x in rule_parameters["prohibitedPorts"].split(',')] 
    sqs_url = rule_parameters.get("sqsUrl")
    
    result_token = "No token found."
    if "resultToken" in event:
        result_token = event["resultToken"]

    evaluation = evaluate_compliance(configuration_item, prohibited_ports)
    print(evaluation)

    if sqs_url:
        if "violations" in evaluation:
            for v in evaluation["violations"][1]:
                queue_violation(sqs_url, configuration_item["configuration"].get("groupId"), v)

    print(evaluation)
    
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

import json
import boto3
import botocore

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

bucket_policy.load()

print json.dumps(bucket_policy)
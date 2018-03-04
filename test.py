import json
import boto3
import botocore

s3 = boto3.resource('s3')
bucket_acl = s3.BucketAcl('ddaws-knownpublicbucket1')

grants = bucket_acl.grants

for grant in grants:
    if grant["Grantee"]["Type"] == "Group":
        if grant["Grantee"]["URI"] in ["http://acs.amazonaws.com/groups/global/AllUsers", "http://acs.amazonaws.com/groups/global/AllAuthenticatedUsers"]:
            print("Identified AllUsers or AllAuthenticatedUsers, removing grant.")
            grants.remove(grant)


response = bucket_acl.put(
    AccessControlPolicy={
        'Grants': grants,
        'Owner': bucket_acl.owner
    }
)

bucket_acl.load()

print bucket_acl
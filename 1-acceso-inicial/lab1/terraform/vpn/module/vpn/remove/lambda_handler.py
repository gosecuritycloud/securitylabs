import json
import boto3
import os
import datetime

# Initialize clients
ec2 = boto3.client('ec2')

SECURITY_GROUP_ID = os.environ.get('SECURITY_GROUP_ID')  
EXPIRATION_TIMEOUT = os.environ.get('EXPIRATION_TIMEOUT')
sg_list = SECURITY_GROUP_ID.split(",")

def lambda_handler(event, context):
    """Removes IPs from security groups if their timestamp is older than 8 hours."""
    now = datetime.datetime.utcnow()
    hours_ago = now - datetime.timedelta(hours=EXPIRATION_TIMEOUT)

    for sg in sg_list:
        if sg != '': 
            try:
                response = ec2.describe_security_group_rules(Filters=[ {'Name': 'group-id','Values': [sg]}])

                for rule in response['SecurityGroupRules']:
                    if 'Description' in rule['IpRanges'][0]:
                        try:
                            rule_time = datetime.datetime.fromisoformat(rule['IpRanges'][0]['Description'])
                            if rule_time <= hours_ago:
                                ec2.revoke_security_group_ingress(GroupId=sg,SecurityGroupRuleIds=[rule['SecurityGroupRuleId']])
                        except ValueError:
                            print(f"Invalid timestamp format in rule {rule['SecurityGroupRuleId']}")
            except Exception as e:
                            print(f"Error processing security group {e}")
        
        # Return the combined response
    return {
        "statusCode": 200,
        "body": json.dumps({
            "response": "removed"
        })
    }
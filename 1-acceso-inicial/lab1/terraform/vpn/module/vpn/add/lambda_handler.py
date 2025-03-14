import json
import boto3
import os
import datetime

# Initialize clients
s3 = boto3.client('s3')
ec2 = boto3.client('ec2')

# Environment variables for bucket and security group
BUCKET_NAME = os.environ.get('BUCKET_NAME')
KEY_PREFIX = os.environ.get('KEY_PREFIX', 'ips/')
SECURITY_GROUP_ID = os.environ.get('SECURITY_GROUP_ID')  
PORT = os.environ.get('PORT')
sg_list = SECURITY_GROUP_ID.split(",")
port_list = PORT.split(",")


def add_ip_to_security_group(ip):
    timestamp = datetime.datetime.utcnow().isoformat()

    try:
        for sg in sg_list:
            if sg != '':
                for port in port_list: 
                    response = ec2.authorize_security_group_ingress(
                        GroupId=sg,
                        IpPermissions=[
                            {
                                'IpProtocol': 'tcp',  # -1 means all protocols; adjust if needed
                                'FromPort': int(port),
                                'ToPort': int(port),
                                'IpRanges': [
                                    {'CidrIp': f'{ip}/32', 'Description': str(timestamp)}
                                ]
                            }
                        ]
                    )
        return {"status": "ready"}
    except Exception as e:
        # In case the rule already exists or another error occurs, return the error message.
        error = e
        return {"message": "ip already authorized"}

def lambda_handler(event, context):
    try:
        # Retrieve source IP from API Gateway's requestContext (common for REST APIs)
        ip = event.get('requestContext', {}).get('identity', {}).get('sourceIp')
        
        
        # If not found, try retrieving it from headers (e.g. for HTTP API Gateway)
        if not ip:
            ip = event.get('headers', {}).get('X-Forwarded-For', '')
            ip = ip.split(',')[0].strip() if ip else 'Unknown'
        
        # Create a unique object key for the stored IP using the current UTC time.
        timestamp = datetime.datetime.utcnow().isoformat()
        object_key = f"{KEY_PREFIX}{timestamp}_{ip}"
        
        
        # s3.put_object(
        #     Bucket=BUCKET_NAME,
        #     Key=object_key,
        #     Body=ip.encode('utf-8')
        # )
        
        # Add the IP to the security group
        
        sg_response = add_ip_to_security_group(ip)
        
        # Return the combined response
        return {
            "statusCode": 200,
            "body": json.dumps({
                "ip": ip,
                "response": sg_response
            })
        }
    except Exception as e:
        # Log error and return an error response
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str("nope")
            })
        }

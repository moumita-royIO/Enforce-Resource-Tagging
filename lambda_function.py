import boto3

ec2 = boto3.client('ec2')
rds = boto3.client('rds')
s3 = boto3.client('s3')

REQUIRED_TAGS = ["Environment", "Owner", "Keep_Until"]


def check_tags(tag_list, resource_name):
    """Validate required tags are present."""
    existing_keys = [tag["Key"] for tag in tag_list]
    missing = [tag for tag in REQUIRED_TAGS if tag not in existing_keys]

    if missing:
        print(f"{resource_name} is missing tags: {missing}")
        return False
    print(f"{resource_name} has all required tags.")
    return True


def handle_ec2(event):
    """Check EC2 instance for required tags and terminate if missing."""
    instance_id = event['detail']['responseElements']['instancesSet']['items'][0]['instanceId']
    print(f"New EC2 instance launched: {instance_id}")

    reservations = ec2.describe_instances(InstanceIds=[instance_id])['Reservations']
    tags = reservations[0]['Instances'][0].get('Tags', [])

    if not check_tags(tags, f"EC2 {instance_id}"):
        print(f"Terminating EC2 {instance_id}...")
        ec2.terminate_instances(InstanceIds=[instance_id])


def handle_rds(event):
    """Check RDS instance for required tags and delete if missing."""
    db_id = event['detail']['responseElements']['dBInstanceIdentifier']
    db_arn = event['detail']['responseElements']['dBInstanceArn']
    print(f"New RDS instance created: {db_id}")

    response = rds.list_tags_for_resource(ResourceName=db_arn)
    tags = response.get('TagList', [])

    if not check_tags(tags, f"RDS {db_id}"):
        print(f"Deleting RDS {db_id} (missing tags)...")
        rds.delete_db_instance(DBInstanceIdentifier=db_id, SkipFinalSnapshot=True)


def handle_s3(event):
    """Check S3 bucket for required tags and delete if missing."""
    bucket_name = event['detail']['requestParameters']['bucketName']
    print(f"New S3 bucket created: {bucket_name}")

    try:
        tagging = s3.get_bucket_tagging(Bucket=bucket_name)
        tags = tagging.get('TagSet', [])
    except s3.exceptions.ClientError as e:
        if "NoSuchTagSet" in str(e):
            tags = []
        else:
            raise

    if not check_tags(tags, f"S3 bucket {bucket_name}"):
        print(f"Deleting S3 bucket {bucket_name} (missing tags)...")
        try:
            s3.delete_bucket(Bucket=bucket_name)
        except Exception as e:
            print(f"Failed to delete bucket {bucket_name}: {e}")


def lambda_handler(event, context):
    """Router to handle EC2, RDS, or S3 events."""
    print("Received event:", event)

    try:
        source = event.get("source")
        if source == "aws.ec2":
            handle_ec2(event)
        elif source == "aws.rds":
            handle_rds(event)
        elif source == "aws.s3":
            handle_s3(event)
        else:
            print(f"Unhandled source: {source}")

    except Exception as e:
        print(f"Error processing event: {str(e)}")

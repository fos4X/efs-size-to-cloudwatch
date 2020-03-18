import json
import boto3

region = "eu-central-1"


def efs_size(event, context):
    efs = boto3.client('efs', region_name=region)
    cw = boto3.client('cloudwatch', region_name=region)

    efs_file_systems = efs.describe_file_systems()['FileSystems']

    for fs in efs_file_systems:
        cw.put_metric_data(
            Namespace="EFS Metrics",
            MetricData=[
                {
                    'MetricName': 'EFS Size',
                    'Dimensions': [{'Name': 'EFS_FileSystemId', 'Value': fs['FileSystemId']}],
                    'Value': fs['SizeInBytes']['Value'],
                    'Unit': 'Bytes',
                },
                {
                    'MetricName': 'EFS IA Size',
                    'Dimensions': [{'Name': 'EFS_FileSystemId', 'Value': fs['FileSystemId']}],
                    'Value': fs['SizeInBytes']['ValueInIA'],
                    'Unit': 'Bytes',
                },
                {
                    'MetricName': 'EFS Standard Size',
                    'Dimensions': [{'Name': 'EFS_FileSystemId', 'Value': fs['FileSystemId']}],
                    'Value': fs['SizeInBytes']['ValueInStandard'],
                    'Unit': 'Bytes',
                },
            ],
        )
    return "Done"

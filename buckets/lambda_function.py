import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    # Tracking compliance
    total_buckets = 0
    compliant_buckets = []
    non_compliant_buckets = []
    
    buckets = s3.list_buckets()
    
    for bucket in buckets['Buckets']:
        bucket_name = bucket['Name']
        total_buckets += 1
        
        try:
            # Check bucket encryption
            encryption = s3.get_bucket_encryption(Bucket=bucket_name)
            
            # Check if encryption is AES256 or KMS
            encryption_rule = encryption['ServerSideEncryptionConfiguration']['Rules'][0]
            encryption_algorithm = encryption_rule['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']
            
            if encryption_algorithm in ['AES256', 'aws:kms']:
                logger.info(f"COMPLIANCE PASSED: Bucket {bucket_name} is encrypted with {encryption_algorithm}.")
                compliant_buckets.append(bucket_name)
            else:
                logger.warning(f"COMPLIANCE WARNING: Bucket {bucket_name} has non-standard encryption.")
                non_compliant_buckets.append(bucket_name)
        
        except s3.exceptions.ClientError as e:
            if e.response['Error']['Code'] == 'ServerSideEncryptionConfigurationNotFoundError':
                logger.warning(f"COMPLIANCE FAILED: Bucket {bucket_name} is NOT encrypted.")
                non_compliant_buckets.append(bucket_name)
            else:
                logger.error(f"ERROR: Failed to check encryption for bucket {bucket_name}: {e}")
    
    # Generate comprehensive compliance report
    compliance_report = {
        "total_buckets": total_buckets,
        "compliant_buckets": compliant_buckets,
        "non_compliant_buckets": non_compliant_buckets,
        "compliance_percentage": len(compliant_buckets) / total_buckets * 100 if total_buckets > 0 else 0
    }
    
    logger.info(f"COMPLIANCE SUMMARY: {compliance_report}")
    
    return {
        "statusCode": 200,
        "body": f"Encryption compliance check complete. Total Buckets: {total_buckets}, Compliant: {len(compliant_buckets)}, Non-Compliant: {len(non_compliant_buckets)}"
    }
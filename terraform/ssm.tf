########################
# Ansible SSM S3 Bucket
########################

resource "aws_s3_bucket" "ansible_ssm" {
  bucket_prefix = "${var.environment}-ansible-ssm-"

  tags = {
    Name        = "${var.environment}-ansible-ssm"
    Environment = var.environment
  }
}

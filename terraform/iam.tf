############################
#   IAM Role for EC2 SSM   #
############################

resource "aws_iam_role" "ssm_role" {
  name = "${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-ssm-role"
    Environment = var.environment
  }
}

############################
#   SSM Policy Attachment  #
############################

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

########################
# EC2 Instance Profile #
########################

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

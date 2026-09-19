data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#############################
# Application EC2 Instances #
#############################
resource "aws_instance" "application" {
  count = 2

  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
  #!/bin/bash
  dnf install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm

  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent

  echo "===== SSM DEBUG =====" > /dev/console
  systemctl status amazon-ssm-agent --no-pager > /dev/console 2>&1
  echo "===== SSM LOG =====" > /dev/console
  tail -50 /var/log/amazon/ssm/amazon-ssm-agent.log > /dev/console 2>&1
  echo "===== SSM STATUS =====" > /dev/console
  systemctl status amazon-ssm-agent --no-pager > /dev/console 2>&1
EOF

  subnet_id = count.index == 0 ? (
    aws_subnet.application_private_subnet_a.id
    ) : (
    aws_subnet.application_private_subnet_b.id
  )

  vpc_security_group_ids = [
    aws_security_group.application_sg.id
  ]
  tags = {
    Name        = "${var.environment}-application-${count.index + 1}"
    Environment = var.environment
    Role        = "application"
  }
}

##########################
# Database EC2 Instances #
##########################

resource "aws_instance" "database" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
  #!/bin/bash
  dnf install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm

  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent

  echo "===== SSM DEBUG =====" > /dev/console
  systemctl status amazon-ssm-agent --no-pager > /dev/console 2>&1
  echo "===== SSM LOG =====" > /dev/console
  tail -50 /var/log/amazon/ssm/amazon-ssm-agent.log > /dev/console 2>&1
  echo "===== SSM STATUS =====" > /dev/console
  systemctl status amazon-ssm-agent --no-pager > /dev/console 2>&1
EOF

  subnet_id = aws_subnet.application_private_subnet_a.id

  vpc_security_group_ids = [
    aws_security_group.database_sg.id
  ]

  tags = {
    Name        = "${var.environment}-database"
    Environment = var.environment
    Role        = "database"
  }
}

resource "aws_lb_target_group_attachment" "application" {
  count = 2

  target_group_arn = aws_lb_target_group.application_target_group.arn
  target_id        = aws_instance.application[count.index].id
  port             = 80
}

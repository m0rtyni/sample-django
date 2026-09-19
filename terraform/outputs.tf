########################
#   Terraform Outputs  #
########################

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.application_load_balancer.dns_name
}

output "vpc_id" {
  description = "ID of the application VPC"
  value       = aws_vpc.application_vpc.id
}

#######################
#    Ansible Files    #
#######################

resource "local_file" "db_ip" {
  content = templatefile("${path.module}/ips.tpl", {
    ips = [aws_instance.database.private_ip]
  })

  filename = "${path.module}/../ansible/db_ip"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    web_ids         = aws_instance.application[*].id
    db_id           = aws_instance.database.id
    aws_region      = var.aws_region
    ssm_bucket_name = aws_s3_bucket.ansible_ssm.bucket
  })

  filename = "${path.module}/../ansible/inventory.ini"
}

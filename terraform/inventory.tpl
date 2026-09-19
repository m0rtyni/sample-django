[webservers]
%{ for id in web_ids ~}
${id}
%{ endfor ~}

[database]
${db_id}

[all:vars]
ansible_connection=amazon.aws.aws_ssm
ansible_aws_ssm_region=${aws_region}
ansible_aws_ssm_bucket_name=${ssm_bucket_name}
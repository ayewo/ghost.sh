output "instance_0" {
  description = "A summary of created resources."
  value       = "Any output that ends with ${var.output_suffix} is not an added resource. It is simply a resource tag."
}

output "instance_id" {
  description = "AWS-assigned ID for the EC2 instance."
  value       = aws_instance.web_server.id
}

output "instance_name" {
  description = "Human-readable name for the EC2 instance."
  value       = "${aws_instance.web_server.tags["Name"]} ${var.output_suffix}"
}

output "instance_p_elastic_ip" {
  description = "AWS-assigned ID Elastic IP address for the EC2 instance."
  value       = aws_eip.eip.public_ip
}

output "instance_p_elastic_ip__dns" {
  description = "Human-readable DNS name for the allocated elastic IP."
  value       = "${aws_eip.eip.public_dns} ${var.output_suffix}"
}



output "instance_p_elastic_ip_allocation_id" {
  description = "AWS-assigned ID for the Elastic IP-to-EC2 instance association."
  value       = aws_eip.eip.allocation_id
}

output "instance_p_elastic_ip_allocation_name" {
  description = "Human-readable name for the allocated elastic IP."
  value       = "${aws_eip.eip.tags["Name"]} ${var.output_suffix}"
}

output "instance_security_group_id" {
  description = "AWS-assigned ID for the security group."
  value       = aws_security_group.ghost_security_group.id
}

output "instance_security_group_id_name" {
  description = "Human-readable name for the security group."
  value       = "${aws_security_group.ghost_security_group.name} ${var.output_suffix}"
}


output "instance_sg_rule1_id" {
  description = "AWS-assigned ID for rule #1 in the security group."
  value       = aws_security_group_rule.ingress80.id
}

output "instance_sg_rule2_id" {
  description = "AWS-assigned ID for rule #2 in the security group."
  value       = aws_security_group_rule.ingress443.id
}

output "instance_sg_rule3_id" {
  description = "AWS-assigned ID for rule #3 in the security group."
  value       = aws_security_group_rule.ingress22.id
}

output "instance_sg_rule4_id" {
  description = "AWS-assigned ID for rule #4 in the security group."
  value       = aws_security_group_rule.egressAny.id
}


output "instance_sg_rule1_name" {
  description = "Human-readable name for rule #1 in the security group."
  value       = aws_ec2_tag.ghost_security_group_rule_tag1.value
}

output "instance_sg_rule2_name" {
  description = "Human-readable name for rule #2 in the security group."
  value       = aws_ec2_tag.ghost_security_group_rule_tag2.value
}

output "instance_sg_rule3_name" {
  description = "Human-readable name for rule #3 in the security group."
  value       = aws_ec2_tag.ghost_security_group_rule_tag3.value
}

output "instance_sg_rule4_name" {
  description = "Human-readable name for rule #4 in the security group."
  value       = aws_ec2_tag.ghost_security_group_rule_tag4.value
}


output "instance_ghost_mysql_password" {
  description = "Terraform-generated MySQL password for Ghost on the EC2 instance."
  value       = random_id.ghost_mysql_password.id
  sensitive   = true
}

output "instance_ghost_admin_password" {
  description = "Terraform-generated password for the Ghost Admin on the EC2 instance."
  value       = random_id.ghost_admin_password.id
  sensitive   = true
}


# output "instance_public_ip" {
#   description = "Public IP address of the EC2 instance."
#   value       = aws_instance.web_server.public_ip
# }


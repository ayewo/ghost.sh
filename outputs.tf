output "instance_0" {
  description = "A summary of created resources."
  value       = "Any output that ends with ${var.output_suffix} is not an added resource. It is simply a resource tag."
}


# ----------------------------------------------------------------------------
# Shared: meaningful whichever cloud the blog was built on
# ----------------------------------------------------------------------------

output "cloud_provider" {
  description = "The cloud this blog was built on."
  value       = var.cloud_provider
}

output "server_public_ip" {
  description = "The reserved public IP address of your Ghost server."
  value       = local.public_ip
}

output "server_ssh_command" {
  description = "Ready-made command for administering your Ghost server."
  value       = "ssh -i ${var.ghost_admin_ssh_private_key} ${var.ghost_admin}@${local.public_ip}"
}

output "server_blog_url" {
  description = "Where your blog is reachable. ghost.sh only serves this over https:// once a certificate was issued, so read /etc/ghost.sh/install.env on the server for the URL it actually configured."
  value       = var.ghost_blog_domain != "" ? "https://${var.ghost_blog_domain}" : "http://ghost-sh-${replace(local.public_ip, ".", "-")}.nip.io"
}


# ----------------------------------------------------------------------------
# AWS: null when cloud_provider = "digitalocean"
# ----------------------------------------------------------------------------

output "instance_id" {
  description = "AWS-assigned ID for the EC2 instance."
  value       = one(aws_instance.web_server[*].id)
}

output "instance_name" {
  description = "Human-readable name for the EC2 instance."
  value       = local.on_aws ? "${one(aws_instance.web_server[*].tags["Name"])} ${var.output_suffix}" : null
}

output "instance_p_elastic_ip" {
  description = "AWS-assigned ID Elastic IP address for the EC2 instance."
  value       = one(aws_eip.eip[*].public_ip)
}

output "instance_p_elastic_ip__dns" {
  description = "Human-readable DNS name for the allocated elastic IP."
  value       = local.on_aws ? "${one(aws_eip.eip[*].public_dns)} ${var.output_suffix}" : null
}

output "instance_p_elastic_ip_allocation_id" {
  description = "AWS-assigned ID for the Elastic IP-to-EC2 instance association."
  value       = one(aws_eip.eip[*].allocation_id)
}

output "instance_p_elastic_ip_allocation_name" {
  description = "Human-readable name for the allocated elastic IP."
  value       = local.on_aws ? "${one(aws_eip.eip[*].tags["Name"])} ${var.output_suffix}" : null
}

output "instance_security_group_id" {
  description = "AWS-assigned ID for the security group."
  value       = one(aws_security_group.ghost_security_group[*].id)
}

output "instance_security_group_id_name" {
  description = "Human-readable name for the security group."
  value       = local.on_aws ? "${one(aws_security_group.ghost_security_group[*].name)} ${var.output_suffix}" : null
}


output "instance_sg_rule1_id" {
  description = "AWS-assigned ID for rule #1 in the security group."
  value       = one(aws_security_group_rule.ingress80[*].id)
}

output "instance_sg_rule2_id" {
  description = "AWS-assigned ID for rule #2 in the security group."
  value       = one(aws_security_group_rule.ingress443[*].id)
}

output "instance_sg_rule3_id" {
  description = "AWS-assigned ID for rule #3 in the security group."
  value       = one(aws_security_group_rule.ingress22[*].id)
}

output "instance_sg_rule4_id" {
  description = "AWS-assigned ID for rule #4 in the security group."
  value       = one(aws_security_group_rule.egressAny[*].id)
}


output "instance_sg_rule1_name" {
  description = "Human-readable name for rule #1 in the security group."
  value       = one(aws_ec2_tag.ghost_security_group_rule_tag1[*].value)
}

output "instance_sg_rule2_name" {
  description = "Human-readable name for rule #2 in the security group."
  value       = one(aws_ec2_tag.ghost_security_group_rule_tag2[*].value)
}

output "instance_sg_rule3_name" {
  description = "Human-readable name for rule #3 in the security group."
  value       = one(aws_ec2_tag.ghost_security_group_rule_tag3[*].value)
}

output "instance_sg_rule4_name" {
  description = "Human-readable name for rule #4 in the security group."
  value       = one(aws_ec2_tag.ghost_security_group_rule_tag4[*].value)
}


# ----------------------------------------------------------------------------
# DigitalOcean: null when cloud_provider = "aws"
# ----------------------------------------------------------------------------

output "droplet_id" {
  description = "DigitalOcean-assigned ID for the droplet."
  value       = one(digitalocean_droplet.web_server[*].id)
}

output "droplet_name" {
  description = "Human-readable name for the droplet."
  value       = local.on_digitalocean ? "${one(digitalocean_droplet.web_server[*].name)} ${var.output_suffix}" : null
}

output "droplet_size" {
  description = "The droplet size slug, with its monthly price."
  value       = local.on_digitalocean ? "${one(digitalocean_droplet.web_server[*].size)} (USD ${one(digitalocean_droplet.web_server[*].price_monthly)}/month) ${var.output_suffix}" : null
}

output "droplet_p_reserved_ip" {
  description = "DigitalOcean-assigned reserved IP address for the droplet."
  value       = one(digitalocean_reserved_ip.eip[*].ip_address)
}

output "droplet_firewall_id" {
  description = "DigitalOcean-assigned ID for the firewall."
  value       = one(digitalocean_firewall.ghost_firewall[*].id)
}

output "droplet_firewall_name" {
  description = "Human-readable name for the firewall."
  value       = local.on_digitalocean ? "${one(digitalocean_firewall.ghost_firewall[*].name)} ${var.output_suffix}" : null
}

output "droplet_ssh_key_fingerprint" {
  description = "Fingerprint of the SSH key registered with DigitalOcean."
  value       = one(digitalocean_ssh_key.ghost_admin[*].fingerprint)
}


# ----------------------------------------------------------------------------
# Credentials
# ----------------------------------------------------------------------------

output "instance_ghost_mysql_password" {
  description = "Terraform-generated MySQL password for Ghost on the server."
  value       = random_id.ghost_mysql_password.id
  sensitive   = true
}

output "instance_ghost_admin_password" {
  description = "Terraform-generated password for the Ghost Admin on the server."
  value       = random_id.ghost_admin_password.id
  sensitive   = true
}

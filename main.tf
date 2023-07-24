terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.40"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

locals {
  instance_name     = "${var.prefix}_${var.instance_name}"
  path_public_key   = "${path.module}/${var.ghost_admin_ssh_public_key}"
  path_private_key  = "${path.module}/${var.ghost_admin_ssh_private_key}"
  path_cloud_config = "${path.module}/cloud-init/cloud-config.yaml"
}

data "local_file" "ghost_admin_ssh_public_key" {
  filename = local.path_public_key
}

data "local_sensitive_file" "ghost_admin_ssh_private_key" {
  filename = local.path_private_key
}


data "template_file" "cloud-config" {
  template = file(local.path_cloud_config)

  vars = {
    ghost_admin_email          = "${var.ghost_admin_email}"
    ghost_admin_ssh_public_key = "${data.local_file.ghost_admin_ssh_public_key.content}"
    ghost_blog_domain          = "${var.ghost_blog_domain}"
    ghost_blog_name            = "${var.ghost_blog_name}"
    ghost_elastic_ip           = aws_eip.eip.public_ip
    ghost_mysql_password       = "${random_id.ghost_mysql_password.id}"
    ghost_admin_password       = "${random_id.ghost_admin_password.id}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-config.rendered
  }
}



resource "aws_eip" "eip" {
  # Comment out this reference as it caused a circular dependency
  #instance = aws_instance.web_server.id
  tags = {
    Name = "${local.instance_name}_elastic-ip"
  }
}

resource "aws_eip_association" "elastic_ip_association" {
  instance_id   = aws_instance.web_server.id
  allocation_id = aws_eip.eip.id
}

resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = "t2.small"
  vpc_security_group_ids = [aws_security_group.ghost_security_group.id]
  user_data              = data.template_cloudinit_config.config.rendered

  tags = {
    Name = local.instance_name
  }

  connection {
    type        = "ssh"
    user        = var.ghost_admin
    private_key = data.local_sensitive_file.ghost_admin_ssh_private_key.content
    host        = aws_eip.eip.public_ip
  }

  provisioner "local-exec" {
    command    = "echo The server IP address is ${self.public_ip}."
    on_failure = continue
  }

  provisioner "local-exec" {
    command    = "echo The server [Elastic] IP address is ${aws_eip.eip.public_ip} but is not yet associated."
    on_failure = continue
  }

  provisioner "remote-exec" {
    connection {
      # /Elastic IP/ association happens after instance creation but instance provisioning after instance creation takes about 6m50s.
      # Because of this order, this remote-exec SSH connection eventually times out then fails (because the default timeout is 5m30s < 6m50s).
      # Rather than wait ~7mins for the /Elastic IP/ to be associated, this workaround uses the instance's /public IP/ (while it is still available)
      # to connect immediately for SSH access.

      # host        = aws_eip.eip.public_ip
      host = self.public_ip
    }
    inline = [
      "cloud-init status --wait",
      "nginx -v",
      "certbot --version",
      "mysql --version",
      "node --version && npm --version",
      "ghost --version",
      "ghost ls"
    ]
    on_failure = continue
  }
}

resource "random_id" "ghost_mysql_password" {
  byte_length = 16
}

resource "random_id" "ghost_admin_password" {
  byte_length = 16
}

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

data "template_file" "ghost_admin_ssh_key" {
  template = "${file("${var.ghost_admin_ssh_key}")}"
}

data "template_file" "cloud-config" {
  template = "${file("${path.module}/cloud-init/cloud-config.yaml")}"

  vars = {
    ghost_admin_email = "${var.ghost_admin_email}"
    ghost_admin_ssh_key = "${data.template_file.ghost_admin_ssh_key.rendered}"
    ghost_blog_domain = "${var.ghost_blog_domain}"
    ghost_blog_name = "${var.ghost_blog_name}"
    ghost_mysql_password = "${random_id.ghost_mysql_password.id}"
    ghost_admin_password = "${random_id.ghost_admin_password.id}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud-config.rendered}"
  }
}


locals {
  instance_name = "${var.prefix}_${var.instance_name}"
}

resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = "t2.small"
  vpc_security_group_ids = [aws_security_group.ghost_security_group.id]
  user_data              = data.template_cloudinit_config.config.rendered
  
  tags = {
    Name = local.instance_name
  }
}

resource "aws_eip" "eip" {
  instance = aws_instance.web_server.id
  tags = {
    Name = "${local.instance_name}_elastic-ip"  
  }
}

resource "aws_eip_association" "elastic_ip_association" {
  instance_id   = aws_instance.web_server.id
  allocation_id = aws_eip.eip.id
}

resource "random_id" "ghost_mysql_password" {
  byte_length = 16
}

resource "random_id" "ghost_admin_password" {
  byte_length = 16
}

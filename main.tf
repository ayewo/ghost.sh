terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.100"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

# Left null, the provider reads DIGITALOCEAN_TOKEN from the environment. An
# AWS-only run needs no token at all: every DigitalOcean resource below is
# count = 0, and Terraform does not ask a provider for credentials it has no
# resources to manage.
provider "digitalocean" {
  token = var.do_token
}

locals {
  instance_name     = "${var.prefix}_${var.instance_name}"
  path_public_key   = "${path.module}/${var.ghost_admin_ssh_public_key}"
  path_private_key  = "${path.module}/${var.ghost_admin_ssh_private_key}"
  path_cloud_config = "${path.module}/cloud-init/cloud-config.yaml"

  on_aws          = var.cloud_provider == "aws"
  on_digitalocean = var.cloud_provider == "digitalocean"
}

data "local_file" "ghost_admin_ssh_public_key" {
  filename = local.path_public_key
}

data "local_sensitive_file" "ghost_admin_ssh_private_key" {
  filename = local.path_private_key
}

locals {
  # Both providers hand out a floating address that can be reserved before the
  # server exists. That ordering is what lets the address be baked into the
  # cloud-config, which needs it to derive the nip.io fallback domain.
  public_ip = local.on_aws ? one(aws_eip.eip[*].public_ip) : one(digitalocean_reserved_ip.eip[*].ip_address)

  cloud_config = templatefile(local.path_cloud_config, {
    ghost_admin_email          = var.ghost_admin_email
    ghost_admin_ssh_public_key = data.local_file.ghost_admin_ssh_public_key.content
    ghost_blog_domain          = var.ghost_blog_domain
    ghost_blog_name            = var.ghost_blog_name
    ghost_elastic_ip           = local.public_ip
    ghost_mysql_password       = random_id.ghost_mysql_password.id
    ghost_admin_password       = random_id.ghost_admin_password.id
    ghost_ssl_staging          = tostring(var.ghost_ssl_staging)
    ghost_ssl_force            = tostring(var.ghost_ssl_force)
    ghost_version              = var.ghost_version
    ghost_cli_version          = var.ghost_cli_version
  })

  # Both servers run the same checks once cloud-init reports done.
  provisioning_checks = [
    "cloud-init status --wait",
    "cat /etc/ghost.sh/install.env",
    "cat /etc/ghost.sh/versions.json",
    "ghost ls",
  ]
}

resource "random_id" "ghost_mysql_password" {
  byte_length = 16
}

resource "random_id" "ghost_admin_password" {
  byte_length = 16
}

/*
variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
}
*/

variable "cloud_provider" {
  description = "Which cloud to build the blog on: \"aws\" or \"digitalocean\"."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "digitalocean"], var.cloud_provider)
    error_message = "cloud_provider must be either \"aws\" or \"digitalocean\"."
  }
}

variable "ghost_admin_email" {
  description = "This is the email address where your Ghost welcome email & SSL cert notifications will be sent."
  type        = string
  default     = "ghost.sh@ayewo.com"
}

variable "ghost_admin_ssh_public_key" {
  description = "This is path to your public key file for passwordless authentication over SSH to your Ghost server."
  type        = string
  default     = "../ghost.sh_ssh/ghost_admin_ssh_key.pub"
}

variable "ghost_admin_ssh_private_key" {
  description = "This is path to your private key file for passwordless authentication over SSH to your Ghost server."
  type        = string
  default     = "../ghost.sh_ssh/ghost_admin_ssh_key"
}

variable "ghost_admin" {
  description = "This is Linux user admin for passwordless authentication over SSH to your Ghost server."
  type        = string
  default     = "ghost-mgr"
}

variable "ghost_blog_domain" {
  description = "This is the domain where your Ghost blog will live. Will use your server's IP if left blank."
  type        = string
  default     = ""
}

variable "ghost_version" {
  description = "The version of Ghost to install. Pinned so that rebuilding gives you the same blog; bump it deliberately."
  type        = string
  default     = "6.63.0"
}

variable "ghost_cli_version" {
  description = "The version of Ghost-CLI to install. Ghost 6.63.0 requires ^1.29.1."
  type        = string
  default     = "1.32.4"
}

variable "ghost_ssl_staging" {
  description = "Request the certificate from Let's Encrypt's staging CA instead of the real one. Useful for rehearsing a deploy: the certificate is untrusted by browsers but does not consume the production rate limit."
  type        = bool
  default     = false
}

variable "ghost_ssl_force" {
  description = "Request a certificate even when ghost.sh had to fall back to a nip.io domain. Off by default: Let's Encrypt rate-limits per registered domain and nip.io is not on the Public Suffix List, so every nip.io user shares one quota."
  type        = bool
  default     = false
}

variable "ghost_blog_name" {
  description = "This is the title (aka name) of your Ghost blog. E.g. John Gruber's blog is named 'Daring Fireball'."
  type        = string
  default     = "[Ghost.sh] Self-Hosted Blog"
}


variable "region" {
  description = "The AWS region where your Ghost blog and related resources will be created in."
  type        = string
  default     = "eu-west-2"
}

variable "prefix" {
  description = "The name prefix for all resources created by ghost.sh."
  type        = string
  default     = "ghost.sh"
}

variable "output_suffix" {
  description = "The suffix for all resources tagged by ghost.sh."
  type        = string
  default     = "[#tag]"
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "web-server"
}

variable "instance_type" {
  description = "The EC2 instance type for your Ghost server."
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "Pin the EC2 instance to a specific AMI. Left null, ghost.sh looks up Canonical's newest Ubuntu 24.04 LTS image for the selected region."
  type        = string
  default     = null
}


variable "do_token" {
  description = "DigitalOcean personal access token, needed only when cloud_provider is \"digitalocean\". Left unset, the provider reads DIGITALOCEAN_TOKEN from the environment, which keeps it out of your .tfvars."
  type        = string
  default     = null
  sensitive   = true
}

variable "do_region" {
  description = "The DigitalOcean region to build the droplet in. Defaults to London, to match the eu-west-2 default on AWS."
  type        = string
  default     = "lon1"
}

variable "do_droplet_size" {
  description = "The droplet size slug. s-1vcpu-1gb is Ghost's stated 1 GB minimum, which the provisioned swapfile is what makes workable."
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "do_image" {
  description = "The droplet image slug. Ghost supports Ubuntu 22.04, 24.04 and 26.04."
  type        = string
  default     = "ubuntu-24-04-x64"
}

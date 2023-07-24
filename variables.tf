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

variable "ami_id" {
  description = "Ubuntu Linux AMI for the selected region"
  type        = string
  default     = "ami-09744628bed84e434"
}

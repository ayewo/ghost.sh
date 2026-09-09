# ----------------------------------------------------------------------------
# AWS: created when cloud_provider = "aws"
# ----------------------------------------------------------------------------

# Canonical's own account. Pinning the owner is what stops a lookalike AMI name
# published by anyone else from matching.
data "aws_ami" "ubuntu" {
  count = local.on_aws ? 1 : 0

  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "eip" {
  count = local.on_aws ? 1 : 0

  # Comment out this reference as it caused a circular dependency
  #instance = aws_instance.web_server.id
  tags = {
    Name = "${local.instance_name}_elastic-ip"
  }
}

resource "aws_eip_association" "elastic_ip_association" {
  count = local.on_aws ? 1 : 0

  instance_id   = aws_instance.web_server[0].id
  allocation_id = aws_eip.eip[0].id
}

resource "aws_instance" "web_server" {
  count = local.on_aws ? 1 : 0

  ami                    = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ghost_security_group[0].id]
  user_data              = local.cloud_config

  tags = {
    Name = local.instance_name
  }

  # The provisioning checks run from terraform_data.provisioning_checks in
  # main.tf, so that the elastic IP is associated before cloud-init needs it.
  provisioner "local-exec" {
    command    = "echo The server IP address is ${self.public_ip}."
    on_failure = continue
  }

  provisioner "local-exec" {
    command    = "echo The server [Elastic] IP address is ${aws_eip.eip[0].public_ip} and is about to be associated."
    on_failure = continue
  }
}

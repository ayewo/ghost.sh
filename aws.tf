# ----------------------------------------------------------------------------
# AWS: created when cloud_provider = "aws"
# ----------------------------------------------------------------------------

# Skipped entirely when ami_id pins an image, so a pinned deployment needs no
# ec2:DescribeImages permission and makes no call it will not use.
data "aws_ami" "ubuntu" {
  count = local.on_aws && var.ami_id == null ? 1 : 0

  most_recent = true

  # Canonical's own account. Pinning the owner is what stops a lookalike AMI
  # name published by anyone else from matching.
  owners = ["099720109477"]

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

  # Deliberately not `instance = ...`: aws_eip_association below attaches this,
  # which is what keeps the address allocatable before the server exists.
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

  ami                    = coalesce(var.ami_id, one(data.aws_ami.ubuntu[*].id))
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ghost_security_group[0].id]
  user_data              = local.cloud_config

  tags = {
    Name = local.instance_name
  }

  # The AMI is looked up with most_recent, so it changes whenever Canonical
  # publishes a new Noble image -- and ami forces replacement, which would have a
  # later routine apply destroy and rebuild a running blog. Rebuild on a new
  # image only when you ask for it, by tainting or by bumping ami_id.
  lifecycle {
    ignore_changes = [ami]
  }
}

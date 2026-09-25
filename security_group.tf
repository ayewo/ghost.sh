# ----------------------------------------------------------------------------
# AWS security group: created when cloud_provider = "aws".
# The DigitalOcean equivalent is digitalocean_firewall in digitalocean.tf.
# ----------------------------------------------------------------------------

resource "aws_security_group" "ghost_security_group" {
  count = local.on_aws ? 1 : 0

  name        = "${var.prefix}_security-group"
  description = "Ghost.sh security group"

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
}

# Only available in Terraform AWS Provider version v4.40.0 and up
resource "aws_security_group_rule" "ingress80" {
  count = local.on_aws ? 1 : 0

  security_group_id = aws_security_group.ghost_security_group[0].id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress443" {
  count = local.on_aws ? 1 : 0

  security_group_id = aws_security_group.ghost_security_group[0].id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress22" {
  count = local.on_aws ? 1 : 0

  security_group_id = aws_security_group.ghost_security_group[0].id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egressAny" {
  count = local.on_aws ? 1 : 0

  security_group_id = aws_security_group.ghost_security_group[0].id

  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_ec2_tag" "ghost_security_group_rule_tag1" {
  count = local.on_aws ? 1 : 0

  resource_id = aws_security_group_rule.ingress80[0].security_group_rule_id
  key         = "Name"
  value       = "${var.prefix}_security-group_ingress-80"
}

resource "aws_ec2_tag" "ghost_security_group_rule_tag2" {
  count = local.on_aws ? 1 : 0

  resource_id = aws_security_group_rule.ingress443[0].security_group_rule_id
  key         = "Name"
  value       = "${var.prefix}_security-group_ingress-443"
}

resource "aws_ec2_tag" "ghost_security_group_rule_tag3" {
  count = local.on_aws ? 1 : 0

  resource_id = aws_security_group_rule.ingress22[0].security_group_rule_id
  key         = "Name"
  value       = "${var.prefix}_security-group_ingress-22"
}

resource "aws_ec2_tag" "ghost_security_group_rule_tag4" {
  count = local.on_aws ? 1 : 0

  resource_id = aws_security_group_rule.egressAny[0].security_group_rule_id
  key         = "Name"
  value       = "${var.prefix}_security-group_egress-any"
}

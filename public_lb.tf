#------------------------------------------------------------------------------
# Public-facing Load Balancers for Vault Clusters
#
# These are standalone NLBs that attach to the same ASGs managed by the
# vault_hvd_primary and vault_hvd_pr modules. The existing internal LBs
# are untouched.
#------------------------------------------------------------------------------

#==============================================================================
# PRIMARY CLUSTER — Public NLB (us-west-2)
#==============================================================================

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "public_lb_primary" {
  name   = "vault-public-lb-sg"
  vpc_id = local.w2_vpc_id
  tags   = merge(local.common_tags, { Name = "vault-public-lb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "public_lb_primary_ingress" {
  for_each          = toset(local.public_lb_ingress_cidrs)
  security_group_id = aws_security_group.public_lb_primary.id
  cidr_ipv4         = each.value
  from_port         = 8200
  to_port           = 8200
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "public_lb_primary_to_vault" {
  security_group_id            = aws_security_group.public_lb_primary.id
  referenced_security_group_id = data.aws_security_group.vault_primary_instance_sg.id
  from_port                    = 8200
  to_port                      = 8200
  ip_protocol                  = "tcp"
}

# Allow Vault instances to accept traffic from the public LB
resource "aws_vpc_security_group_ingress_rule" "vault_primary_from_public_lb" {
  security_group_id            = data.aws_security_group.vault_primary_instance_sg.id
  referenced_security_group_id = aws_security_group.public_lb_primary.id
  from_port                    = 8200
  to_port                      = 8200
  ip_protocol                  = "tcp"
}

# ── NLB ───────────────────────────────────────────────────────────────────────

resource "aws_lb" "vault_public_primary" {
  name                             = "vault-public"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = data.aws_subnets.public_subnets.ids
  security_groups                  = [aws_security_group.public_lb_primary.id]
  enable_cross_zone_load_balancing = false
  tags                             = local.common_tags
}

# ── Target Group ──────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "vault_public_primary" {
  name                 = "vault-public"
  target_type          = "instance"
  port                 = 8200
  protocol             = "TCP"
  vpc_id               = local.w2_vpc_id
  deregistration_delay = 15
  tags                 = local.common_tags

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
    timeout  = 3
    interval = 5
    path     = "/v1/sys/health?standbyok=true&perfstandbyok=true&activecode=200&standbycode=429&drsecondarycode=472&performancestandbycode=473&sealedcode=503&uninitcode=200"
  }

  stickiness {
    type    = "source_ip"
    enabled = true
  }
}

# ── Listener ──────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "vault_public_primary" {
  load_balancer_arn = aws_lb.vault_public_primary.id
  port              = 8200
  protocol          = "TCP"
  tags              = local.common_tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_public_primary.arn
  }
}

# ── Attach existing ASG to the public target group ────────────────────────────

# resource "aws_autoscaling_attachment" "vault_public_primary" {
#   autoscaling_group_name = "vault-asg"
#   lb_target_group_arn    = aws_lb_target_group.vault_public_primary.arn

#   depends_on = [module.vault_hvd_primary]
# }

#==============================================================================
# PR CLUSTER — Public NLB (us-east-2)
#==============================================================================

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "public_lb_pr" {
  provider = aws.secondary
  name     = "e2prvault-public-lb-sg"
  vpc_id   = module.prereqs_use2.vpc_id
  tags     = merge(local.common_tags, { Name = "e2prvault-public-lb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "public_lb_pr_ingress" {
  for_each          = toset(local.public_lb_ingress_cidrs)
  provider          = aws.secondary
  security_group_id = aws_security_group.public_lb_pr.id
  cidr_ipv4         = each.value
  from_port         = 8200
  to_port           = 8200
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "public_lb_pr_to_vault" {
  provider                     = aws.secondary
  security_group_id            = aws_security_group.public_lb_pr.id
  referenced_security_group_id = data.aws_security_group.vault_pr_instance_sg.id
  from_port                    = 8200
  to_port                      = 8200
  ip_protocol                  = "tcp"
}

# Allow Vault instances to accept traffic from the public LB
resource "aws_vpc_security_group_ingress_rule" "vault_pr_from_public_lb" {
  provider                     = aws.secondary
  security_group_id            = data.aws_security_group.vault_pr_instance_sg.id
  referenced_security_group_id = aws_security_group.public_lb_pr.id
  from_port                    = 8200
  to_port                      = 8200
  ip_protocol                  = "tcp"
}

# ── NLB ───────────────────────────────────────────────────────────────────────

resource "aws_lb" "vault_public_pr" {
  provider                         = aws.secondary
  name                             = "e2prvault-public"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = module.prereqs_use2.public_subnet_ids
  security_groups                  = [aws_security_group.public_lb_pr.id]
  enable_cross_zone_load_balancing = false
  tags                             = local.common_tags
}

# ── Target Group ──────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "vault_public_pr" {
  provider             = aws.secondary
  name                 = "e2prvault-public"
  target_type          = "instance"
  port                 = 8200
  protocol             = "TCP"
  vpc_id               = module.prereqs_use2.vpc_id
  deregistration_delay = 15
  tags                 = local.common_tags

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
    timeout  = 3
    interval = 5
    path     = "/v1/sys/health?standbyok=true&perfstandbyok=true&activecode=200&standbycode=429&drsecondarycode=472&performancestandbycode=473&sealedcode=503&uninitcode=200"
  }

  stickiness {
    type    = "source_ip"
    enabled = true
  }
}

# ── Listener ──────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "vault_public_pr" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.vault_public_pr.id
  port              = 8200
  protocol          = "TCP"
  tags              = local.common_tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_public_pr.arn
  }
}

# ── Attach existing ASG to the public target group ────────────────────────────

# resource "aws_autoscaling_attachment" "vault_public_pr" {
#   provider               = aws.secondary
#   autoscaling_group_name = "e2prvault-asg"
#   lb_target_group_arn    = aws_lb_target_group.vault_public_pr.arn

#   depends_on = [module.vault_hvd_pr]
# }

#==============================================================================
# Public Route 53 Records
#==============================================================================

resource "aws_route53_record" "vault_public_primary" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.vault_primary_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.vault_public_primary.dns_name
    zone_id                = aws_lb.vault_public_primary.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "vault_public_pr" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.vault_pr
  type    = "A"

  alias {
    name                   = aws_lb.vault_public_pr.dns_name
    zone_id                = aws_lb.vault_public_pr.zone_id
    evaluate_target_health = true
  }
}

# Public CNAME for the main vault FQDN — mirrors the private-zone CNAME
resource "aws_route53_record" "vault_public_cname" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.vault_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [local.vault_primary_fqdn]
}

#------------------------------------------------------------------------------
# Cross-region VPC Peering: us-west-2 (primary) <-> us-east-2 (secondary)
#------------------------------------------------------------------------------

# --- VPC data sources (for CIDRs) ---
data "aws_vpc" "primary" {
  id = local.w2_vpc_id
}

data "aws_vpc" "secondary" {
  provider = aws.secondary
  id       = module.prereqs_use2.vpc_id
}

# --- Route table data sources (private subnets) ---
data "aws_route_tables" "primary_private" {
  vpc_id = local.w2_vpc_id

  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.private_subnets.ids
  }
}

data "aws_route_tables" "secondary_private" {
  provider = aws.secondary
  vpc_id   = module.prereqs_use2.vpc_id

  filter {
    name   = "association.subnet-id"
    values = module.prereqs_use2.private_subnet_ids
  }
}

# --- Peering connection ---
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  vpc_id      = local.w2_vpc_id
  peer_vpc_id = module.prereqs_use2.vpc_id
  peer_region = local.secondary_region
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "vault-primary-to-secondary"
  })
}

resource "aws_vpc_peering_connection_accepter" "secondary" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "vault-secondary-from-primary"
  })
}

# --- DNS resolution across the peering connection ---
resource "aws_vpc_peering_connection_options" "primary_dns" {
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary]
}

resource "aws_vpc_peering_connection_options" "secondary_dns" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary]
}

# --- Associate private DNS zone with secondary VPC ---
# MOVED TO VPC definition in tfe-hvd :notlikethis"
# resource "aws_route53_zone_association" "secondary" {
#   vpc_id  = module.prereqs_use2.vpc_id
#   zone_id = data.aws_route53_zone.zone.zone_id

#   vpc_region = local.secondary_region
# }

# --- Routes: primary private subnets -> secondary VPC CIDR ---
resource "aws_route" "primary_to_secondary" {
  for_each = toset(data.aws_route_tables.primary_private.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}

# --- Routes: secondary private subnets -> primary VPC CIDR ---
resource "aws_route" "secondary_to_primary" {
  for_each = toset(data.aws_route_tables.secondary_private.ids)
  provider = aws.secondary

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.primary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}

# --- Security group rules: 8201 cluster port (not handled by module CIDR input) ---
# The module's net_ingress_vault_cidr_blocks handles 8200. For 8201 (cluster),
# we add rules directly to each module's internal security group.

data "aws_security_group" "vault_primary_sg" {
  filter {
    name   = "group-name"
    values = ["vault-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [local.w2_vpc_id]
  }

  depends_on = [module.vault_hvd_primary]
}

data "aws_security_group" "vault_secondary_sg" {
  provider = aws.secondary

  filter {
    name   = "group-name"
    values = ["e2prvault-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [module.prereqs_use2.vpc_id]
  }

  depends_on = [module.vault_hvd_pr]
}

resource "aws_security_group_rule" "primary_cluster_from_secondary" {
  type              = "ingress"
  from_port         = 8201
  to_port           = 8201
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.secondary.cidr_block]
  description       = "Vault cluster port from secondary VPC via peering"
  security_group_id = data.aws_security_group.vault_primary_sg.id
}

resource "aws_security_group_rule" "secondary_cluster_from_primary" {
  provider = aws.secondary

  type              = "ingress"
  from_port         = 8201
  to_port           = 8201
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.primary.cidr_block]
  description       = "Vault cluster port from primary VPC via peering"
  security_group_id = data.aws_security_group.vault_secondary_sg.id
}

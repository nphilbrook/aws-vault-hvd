#------------------------------------------------------------------------------
# Cross-region VPC Peering: us-west-2 (primary) <-> us-east-2 (secondary)
#------------------------------------------------------------------------------

# --- VPC data sources (for CIDRs) ---
data "aws_vpc" "primary" {
  id = local.vpc_id
}

data "aws_vpc" "secondary" {
  provider = aws.secondary
  id       = module.prereqs_use2.vpc_id
}

# --- Route table data sources (private subnets) ---
data "aws_route_tables" "primary_private" {
  vpc_id = local.vpc_id

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
  vpc_id      = local.vpc_id
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

# --- Security group: primary VPC (allow 8200/8201 from secondary CIDR) ---
resource "aws_security_group" "vault_peering_primary" {
  name        = "vault-peering-primary"
  description = "Allow Vault API/cluster traffic from secondary VPC"
  vpc_id      = local.vpc_id

  tags = merge(local.common_tags, {
    Name = "vault-peering-primary"
  })
}

resource "aws_vpc_security_group_ingress_rule" "primary_8200" {
  security_group_id = aws_security_group.vault_peering_primary.id
  description       = "Vault API from secondary VPC"
  cidr_ipv4         = data.aws_vpc.secondary.cidr_block
  from_port         = 8200
  to_port           = 8200
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "primary_8201" {
  security_group_id = aws_security_group.vault_peering_primary.id
  description       = "Vault cluster from secondary VPC"
  cidr_ipv4         = data.aws_vpc.secondary.cidr_block
  from_port         = 8201
  to_port           = 8201
  ip_protocol       = "tcp"
}

# --- Security group: secondary VPC (allow 8200/8201 from primary CIDR) ---
resource "aws_security_group" "vault_peering_secondary" {
  provider = aws.secondary

  name        = "vault-peering-secondary"
  description = "Allow Vault API/cluster traffic from primary VPC"
  vpc_id      = module.prereqs_use2.vpc_id

  tags = merge(local.common_tags, {
    Name = "vault-peering-secondary"
  })
}

resource "aws_vpc_security_group_ingress_rule" "secondary_8200" {
  provider = aws.secondary

  security_group_id = aws_security_group.vault_peering_secondary.id
  description       = "Vault API from primary VPC"
  cidr_ipv4         = data.aws_vpc.primary.cidr_block
  from_port         = 8200
  to_port           = 8200
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "secondary_8201" {
  provider = aws.secondary

  security_group_id = aws_security_group.vault_peering_secondary.id
  description       = "Vault cluster from primary VPC"
  cidr_ipv4         = data.aws_vpc.primary.cidr_block
  from_port         = 8201
  to_port           = 8201
  ip_protocol       = "tcp"
}

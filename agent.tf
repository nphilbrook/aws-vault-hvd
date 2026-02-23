data "aws_iam_policy_document" "agent_assume_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "agent_policy" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "agent_policy" {
  name   = "agent_policy"
  policy = data.aws_iam_policy_document.agent_policy.json
}

resource "aws_iam_role" "agent_role" {
  name               = "agent_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "agent_policy_attachment" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.agent_policy.arn
}

resource "aws_iam_instance_profile" "agent_profile" {
  name = "agent_profile"
  role = aws_iam_role.agent_role.name
}

data "aws_security_group" "bastion_sg" {
  filter {
    name   = "group-name"
    values = ["agent-sg"]
  }
}

resource "aws_instance" "jump_w2" {
  ami                         = data.hcp_packer_artifact.bastion_rhel.external_identifier
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.agent_profile.name
  instance_type               = "t3a.small"
  key_name                    = local.key_pair_name
  vpc_security_group_ids      = [local.w2_bastion_security_group]

  metadata_options {
    instance_metadata_tags = "enabled"
  }

  user_data                   = templatefile("${path.module}/agent_user_data.tpl", { num_agents = 2 })
  user_data_replace_on_change = true
}

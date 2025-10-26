#######################################
# IT template Servers
#
# template is a <TODO: description>. More docs at
# <TODO: link to runbook>.
#
# TODO:
# * DNS - no dns entries yet; use var.hostname_pattern.
# * multiple node support - do we need to support more than one?

# Lookup the latest Windows Server AMI from SSM Parameter Store
data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-English-Full-Base"
}

resource "aws_instance" "it_template" {
  for_each      = { for i in range(var.quantity) : i => i }
  ami           = data.aws_ssm_parameter.windows_ami.value
  instance_type = var.instance_type

  vpc_security_group_ids = [data.aws_security_group.all.id, aws_security_group.it_template.id]
  subnet_id              = values(local.subnets_by_az)[each.key % length(local.subnets_by_az)]
  key_name               = var.key_name

  # Security: Enable IMDSv2 and require session tokens
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Security: Enable detailed monitoring
  monitoring = true

  tags = merge(
    local.common_tags,
    { name = format(var.hostname_pattern, each.key + 1) },
  )

  lifecycle {
    # the subnet ordering has changed since this was provisioned
    ignore_changes = [subnet_id]
  }
}

resource "aws_ebs_volume" "it_template_db" {
  for_each = { for i in range(var.quantity) : i => i }

  availability_zone = aws_instance.it_template[each.key].availability_zone
  type              = "gp2"
  size              = 500

  # Security: Enable encryption for data at rest
  encrypted  = true
  kms_key_id = var.kms_key_id

  tags = merge(
    local.common_tags,
    { name = format(var.hostname_pattern, each.key + 1) },
  )
}

resource "aws_volume_attachment" "it_template_db" {
  for_each = { for i in range(var.quantity) : i => i }

  device_name = "xvdf"
  volume_id   = aws_ebs_volume.it_template_db[each.key].id
  instance_id = aws_instance.it_template[each.key].id
}

resource "aws_security_group" "it_template" {
  name        = "it-template-app"
  description = "Access rules for template servers"
  vpc_id      = data.aws_vpc.vpc.id

  # RDP Access (customize CIDR blocks as needed)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Replace with your network CIDR
    description = "RDP access from internal network"
  }

  # Windows File Sharing (SMB)
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/12"]
    description = "Windows file sharing (SMB)"
  }

  # Windows NetBIOS
  ingress {
    from_port   = 135
    to_port     = 139
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/12"]
    description = "Windows NetBIOS services"
  }

  # Restricted egress - HTTPS only for updates and management
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for Windows updates and management"
  }

  # DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  # NTP for time synchronization
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP time synchronization"
  }

  # Internal network communication
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.0.0/12"]
    description = "Internal network communication"
  }

  tags = merge(
    local.common_tags,
    { name = "it-template" },
  )
}

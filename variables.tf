#######################################
# Variables

# Common / shared:

locals {
  common_tags = {
    service     = "windows-server"
    type        = "windows-app"
    contact     = "DevOps Team"
    environment = var.env
  }
}

variable "region" {
  description = "Region to place resources within"
  type        = string
}

variable "env" {
  description = "We don't distinguish"
  type        = string
  default     = "production"
}

# template Application Server

variable "quantity" {
  description = "The number of hosts / volumes / attachments to provision."
  type        = number
  default     = 1
  validation {
    condition     = var.quantity > 0 && var.quantity <= 10
    error_message = "Quantity must be between 1 and 10 instances."
  }
}

variable "hostname_pattern" {
  description = "A hostname pattern, to be used with format() for naming hosts and volumes."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.hostname_pattern))
    error_message = "Hostname pattern must contain only alphanumeric characters, dots, and hyphens."
  }
}

variable "instance_type" {
  description = "Type of EC2 Instance to use. Must support Windows."
  type        = string
  default     = "t3.large"
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be in format 'type.size' (e.g., t3.large)."
  }
}

variable "vpc_name" {
  description = "The name of the VPC these resources are placed into.  Used by a data source to lookup VPC IDs."
  type        = string
  default     = "windows-infrastructure"
  validation {
    condition     = length(var.vpc_name) > 0 && length(var.vpc_name) <= 50
    error_message = "VPC name must be between 1 and 50 characters."
  }
}

variable "subnet_tier" {
  description = "The Tier of subnet for these resources; determines internet connectivity. `internal` or `external`"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["internal", "external"], var.subnet_tier)
    error_message = "Subnet tier must be either 'internal' or 'external'."
  }
}

variable "key_name" {
  description = "SSH Key to create the instance with"
  type        = string
  validation {
    condition     = length(var.key_name) > 0 && length(var.key_name) <= 255
    error_message = "Key name must be between 1 and 255 characters."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for EBS volume encryption. If not provided, AWS default key will be used."
  type        = string
  default     = null
  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws:kms:", var.kms_key_id)) || can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.kms_key_id))
    error_message = "KMS key ID must be either null, a valid ARN, or a valid key ID."
  }
}

variable "terraform_backend_account_id" {
  description = "AWS Account ID for Terraform backend S3 bucket"
  type        = string
  default     = "XXXXXXXXXXXX"  # Replace with your AWS account ID
  validation {
    condition     = can(regex("^[0-9]{12}$", var.terraform_backend_account_id))
    error_message = "Account ID must be exactly 12 digits."
  }
}

variable "terraform_role_account_id" {
  description = "AWS Account ID for Terraform role assumption"
  type        = string
  default     = "900589033387"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.terraform_role_account_id))
    error_message = "Account ID must be exactly 12 digits."
  }
}

#######################################
# Shared Data Sources

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_security_group" "all" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["all"]
  }
}

# Modern subnet data source using aws_subnets instead of deprecated aws_subnet_ids
data "aws_subnets" "template" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Tier"
    values = [var.subnet_tier]
  }
}

data "aws_subnet" "template" {
  for_each = toset(data.aws_subnets.template.ids)
  id       = each.value
}

locals {
  subnets_by_az = {
    for subnet in data.aws_subnet.template : subnet.availability_zone => subnet.id
  }
}

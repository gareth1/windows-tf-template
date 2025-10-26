#######################################
# This moudule currently requires 0.12.x
#
# Do not bump this unless you have pinned all usage to an 0.12 version,
# and commited to updating usage to the new version where possible.

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

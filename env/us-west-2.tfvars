#######################################
# Regional variables
#
# The variables below are all unique to this workspace.

region   = "us-west-2"
key_name = "windows-key-west-2"  # Replace with your EC2 key pair name

# Hostname pattern for your Windows instances
hostname_pattern = "win-server-%d"

# Security: KMS key for EBS encryption (optional - will use AWS default if not specified)
# kms_key_id = "arn:aws:kms:us-west-2:ACCOUNT_ID:key/KEY_ID"

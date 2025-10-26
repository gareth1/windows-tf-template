# Windows Server AWS Terraform Template

This repository provides a reusable Terraform template for deploying the latest Windows Server EC2 instances on AWS. It is designed for rapid, consistent infrastructure provisioning using **Terraform 1.7+** and the **AWS provider 5.x**.

## Features
- **Always uses the latest Windows Server AMI** (automatically fetched from AWS SSM Parameter Store)
- **Customizable instance count and type**
- **Attaches EBS volumes** for data storage with encryption
- **Configurable networking**: VPC, subnets, and security groups
- **Automated resource tagging and naming**
- **Supports role assumption** for secure, cross-account deployments
- **Modern Terraform syntax**: Uses `for_each`, explicit variable types, and up-to-date data sources
- **Security hardened**: IMDSv2, restricted egress, input validation

## Prerequisites
- [Terraform 1.7+](https://www.terraform.io/downloads)
- AWS credentials with permissions to create EC2, VPC, Subnet, Security Group, and EBS resources
- An S3 bucket and DynamoDB table for remote state (if using the provided backend config)
- KMS key for EBS encryption (optional - AWS default key will be used if not specified)

## Getting Started

### 1. Clone the Repository
```sh
git clone <repo-url>
cd Windows-tf-template
```

### 2. Configure Variables
Edit or copy the example variable file in `env/us-west-2.tfvars`:
```hcl
region           = "us-west-2"
key_name         = "your-ssh-key-name"
hostname_pattern = "app%d.template.us-west-2.corp.example.com"
# Optional: Specify KMS key for EBS encryption
# kms_key_id = "arn:aws:kms:us-west-2:ACCOUNT_ID:key/KEY_ID"
```
You can override any variable in `variables.tf` as needed.

### 3. Initialize Terraform
```sh
terraform init
```

### 4. Plan the Deployment
```sh
terraform plan -var-file=env/us-west-2.tfvars
```

### 5. Apply the Deployment
```sh
terraform apply -var-file=env/us-west-2.tfvars
```

## Usage Examples

### Basic Single Instance Deployment
```hcl
# env/us-west-2.tfvars
region           = "us-west-2"
key_name         = "my-windows-key"
hostname_pattern = "win-server-%d"
instance_type    = "t3.large"
quantity         = 1
```

### Multiple Instances with Custom VPC
```hcl
# env/us-west-2.tfvars
region           = "us-west-2"
key_name         = "my-windows-key"
hostname_pattern = "win-server-%d"
instance_type    = "t3.xlarge"
quantity         = 3
vpc_name         = "my-custom-vpc"
subnet_tier      = "internal"
```

### Production Deployment with Enhanced Security
```hcl
# env/us-west-2.tfvars
region           = "us-west-2"
key_name         = "prod-windows-key"
hostname_pattern = "prod-win-%d"
instance_type    = "m5.xlarge"
quantity         = 2
kms_key_id       = "arn:aws:kms:us-west-2:ACCOUNT_ID:key/KEY_ID"
vpc_name         = "prod-vpc"
subnet_tier      = "internal"
```

### Customization Tips

1. **Instance Type Selection**
   - Use `t3.large` for development/testing
   - Use `m5.xlarge` or larger for production workloads
   - Consider `c5` instances for compute-intensive workloads

2. **Networking Configuration**
   - Update security group CIDR blocks in `main.tf` to match your network
   - Use `subnet_tier = "internal"` for better security
   - Consider adding additional security group rules for your applications

3. **Storage Configuration**
   - Default EBS volume size is 500GB
   - Modify `aws_ebs_volume` in `main.tf` to adjust size or type
   - Enable KMS encryption for production environments

4. **Tagging Strategy**
   - Customize `common_tags` in `variables.tf`
   - Add environment-specific tags in your tfvars files
   - Use meaningful hostname patterns for easy identification

### Maintenance Tasks

1. **Updating Windows Server Version**
   - The template automatically uses the latest Windows Server AMI
   - No action required for AMI updates

2. **Security Updates**
   - Regularly update your KMS keys
   - Review and update security group rules
   - Keep Terraform and provider versions current

3. **Backup Strategy**
   - Configure AWS Backup if needed
   - Consider snapshot lifecycle policies
   - Document recovery procedures

## Inputs
| Name                           | Description                                                                 | Type     | Default            | Required |
|--------------------------------|-----------------------------------------------------------------------------|----------|--------------------|:--------:|
| atlantis_user                  | GitHub username for Atlantis runs                                           | string   | "atlantis_user"    |   no     |
| env                            | Environment name                                                            | string   | "production"       |   no     |
| hostname_pattern               | Hostname pattern for naming resources                                       | string   | n/a                |   yes    |
| instance_type                  | EC2 instance type                                                           | string   | "t3.large"         |   no     |
| key_name                       | SSH key name for EC2 instances                                              | string   | n/a                |   yes    |
| kms_key_id                     | KMS key ID for EBS encryption                                               | string   | null               |   no     |
| quantity                       | Number of instances/volumes to provision                                    | number   | 1                  |   no     |
| region                         | AWS region                                                                  | string   | n/a                |   yes    |
| subnet_tier                    | Subnet tier (`internal` or `external`)                                      | string   | "internal"         |   no     |
| terraform_backend_account_id   | AWS Account ID for Terraform backend                                        | string   | "XXXXXXXXXXXX"     |   no     |
| terraform_role_account_id      | AWS Account ID for Terraform role assumption                                | string   | "XXXXXXXXXXXX"     |   no     |
| vpc_name                       | Name of the VPC to deploy resources into                                    | string   | "windows-infrastructure"|   no     |

## Security Features

### Data Protection
- **EBS Volume Encryption**: All EBS volumes are encrypted at rest using AWS KMS
- **IMDSv2**: Instance metadata service requires session tokens
- **Input Validation**: All variables are validated for security and format compliance

### Network Security
- **Restricted Egress**: Outbound traffic limited to essential services (HTTPS, DNS, NTP)
- **Internal Network Access**: RDP access restricted to your specified network CIDR blocks
- **Security Groups**: Granular port and protocol restrictions with descriptive rules

### Access Control
- **Role-Based Access**: Uses AWS IAM roles for secure cross-account access
- **SSH Key Authentication**: Secure key-based authentication for EC2 instances
- **Monitoring**: Detailed monitoring enabled for all instances

### Security Best Practices
- **Latest AMIs**: Always uses the latest Windows Server AMI from AWS SSM
- **Resource Tagging**: Comprehensive tagging for governance and cost tracking
- **Lifecycle Management**: Proper resource lifecycle management with ignore_changes

## Best Practices
- Use a unique S3 key for each environment to avoid state file conflicts
- Use [Terraform workspaces](https://www.terraform.io/docs/language/state/workspaces.html) for managing multiple environments
- Review and restrict security group rules as needed for your organization
- Regularly update the KMS key and rotate access keys
- Monitor CloudTrail logs for unauthorized access attempts
- Use AWS Config rules to ensure compliance with security policies

## Security Considerations

### Before Deployment
1. **Review Security Groups**: Ensure port restrictions meet your security requirements
2. **KMS Key Management**: Consider using a customer-managed KMS key for EBS encryption
3. **Network Access**: Verify that the internal network range (172.16.0.0/12) is appropriate
4. **Monitoring Setup**: Configure CloudWatch alarms and VPC Flow Logs

### Ongoing Security
1. **Regular Updates**: Keep Windows Server instances updated with latest patches
2. **Access Reviews**: Regularly review and rotate SSH keys and IAM roles
3. **Compliance Monitoring**: Use AWS Config to monitor compliance with security policies
4. **Incident Response**: Have procedures in place for security incident response

## License
MIT License. See [LICENSE](LICENSE) for details. 
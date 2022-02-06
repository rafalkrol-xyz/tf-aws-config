# Terraform Module for AWS Config

## Description

A lightweight [Terraform module](https://www.terraform.io/docs/configuration/modules.html) for enabling [AWS Config](https://aws.amazon.com/config/)
within your [AWS Organizations](https://aws.amazon.com/organizations/) organization.

## Pre-requisites

* the [AWS Organizations](https://aws.amazon.com/organizations/) service is used
  * if not, you must handle the [authorization of the Config aggregator](https://docs.aws.amazon.com/config/latest/developerguide/authorize-aggregator-account-console.html) yourself.

### Prerequisites for pre-commit-terraform

**a)** dependencies

The [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform) util requires the latest versions of the following dependencies:

* [pre-commit](https://pre-commit.com/#install)
* [terraform-docs](https://github.com/terraform-docs/terraform-docs)
* [tflint](https://github.com/terraform-linters/tflint)
* [tfsec](https://github.com/aquasecurity/tfsec)
* [terrascan](https://github.com/accurics/terrascan)

On macOS, you can install the above with [brew](https://brew.sh/):

```bash
brew install pre-commit terraform-docs tflint tfsec terrascan
```

**b)** usage

The tool will run automatically before each commit if [git hooks scripts](https://pre-commit.com/#3-install-the-git-hook-scripts) are installed in the project's root:

```bash
pre-commit install
```

For a manual run, execute the below command:

```bash
pre-commit run -a
```

**NB the configuration file is located in `.pre-commit-config.yaml`**

## Usage

```terraform
module "config" {
  source         = "git@github.com:rafalkrol-xyz/tf-aws-config.git"
  s3_bucket_name = "my-organization-governance-and-security-bucket"
  rules          = ["cloud-trail-cloud-watch-logs-enabled", "cloudtrail-enabled", "cloud-trail-log-file-validation-enabled"]
}
```

### Note on tags

[Starting from AWS Provider for Terraform v3.38.0 (with Terraform v0.12 or later onboard), you may define default tags at the provider level, streamlining tag management](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider).
The functionality replaces the now redundant per-resource tags configurations, and therefore, this module has dropped the support of a `tags` variable.
Instead, set the default tags in your parent module:

```terraform
### PARENT MODULE - START
locals {
  tags = {
    key1   = "value1"
    key2   = "value2"
    keyN   = "valueN"
  }
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = local.tags
  }
}

# NB the default tags are implicitly passed into the module: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags
module "config" {
  source             = "git@github.com:rafalkrol-xyz/tf-aws-config.git"
  aggregator_account = true
  s3_bucket_name     = aws_s3_bucket.armatys-governance-and-security.id
  rules              = ["cloud-trail-cloud-watch-logs-enabled", "cloudtrail-enabled", "cloud-trail-log-file-validation-enabled"]
}
### PARENT MODULE - END
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_config_rule.rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_configuration_aggregator.aggregator_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_config_configuration_recorder.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_policy.s3_bucket_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_objects_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.custom_config_service_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_bucket_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_objects_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_service_linked_role.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aggregator_account"></a> [aggregator\_account](#input\_aggregator\_account) | A flag indicating the aggregator\_account account. NB only one per organization is permitted | `bool` | `false` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | A list of of AWS Config Managed Rules to be applied. Must be one of the following: https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html | `list(string)` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | After the terraform docs: 'The name of the S3 bucket used to store the configuration history.' | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Caveats

* the trusted access for AWS Config must be enabled in the root account of your AWS Organizations organization.

```bash
aws organizations enable-aws-service-access --service-principal config.amazonaws.com
aws organizations list-aws-service-access-for-organization
{
    "EnabledServicePrincipals": [
        {
            "ServicePrincipal": "config.amazonaws.com",
            "DateEnabled": "2020-05-30T19:14:25.762000*02:00"
        }
    ]
}
```

* the bucket policy for the Config's destination bucket must be set appropriately.
  * here's an example bucket policy:

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSConfigBucketPermissionsCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::MY-ORGANIZATION-GOVERNANCE-AND-SECURITY-BUCKET" # <---THE DESTINATION BUCKET IN THE AWS ORGANIZATIONS ROOT ACCOUNT
        },
        {
            "Sid": "AWSConfigBucketDelivery",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::MY-ORGANIZATION-GOVERNANCE-AND-SECURITY-BUCKET/AWSLogs/ROOT-ACCOUNT-ID/Config/*", # <---THE DESTINATION BUCKET IN THE AWS ORGANIZATIONS ROOT ACCOUNT PLUS ITS 12-DIGIT ACCOUNT ID
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSConfigS3OBucketPermissionsForSubAccount",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::SUBACCOUNT-ID:root" # <--- THE 12-DIGIT ACCOUNT ID OF THE SUBACCOUNT
                ]
            },
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketAcl"
            ],
            "Resource": "arn:aws:s3:::MY-ORGANIZATION-GOVERNANCE-AND-SECURITY-BUCKET" # <---THE DESTINATION BUCKET IN THE AWS ORGANIZATIONS ROOT ACCOUNT
        },
        {
            "Sid": "AWSConfigS3ObjectsPermissionsForSubAccount",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::754406403550:root"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::MY-ORGANIZATION-GOVERNANCE-AND-SECURITY-BUCKET/AWSLogs/SUBACCOUNT-ID/Config/*", # <---THE DESTINATION BUCKET IN THE AWS ORGANIZATIONS ROOT ACCOUNT PLUS THE 12-DIGIT ACCOUNT ID OF THE SUBACCOUNT
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
  }
  ```

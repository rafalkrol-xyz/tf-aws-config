# Terraform Module for AWS Config

## Description

A lightweight [Terraform module](https://www.terraform.io/docs/configuration/modules.html) for enabling [AWS Config](https://aws.amazon.com/config/)
within your [AWS Organizations](https://aws.amazon.com/organizations/) organization.

## Pre-requisites

+ the [AWS Organizations](https://aws.amazon.com/organizations/) service is used
  + if not, you must handle the [authorization of the Config aggregator](https://docs.aws.amazon.com/config/latest/developerguide/authorize-aggregator-account-console.html) yourself.

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

<!-- BEGINNING OF TERRAFORM DOCS HOOK -->

<!-- END OF TERRAFORM DOCS HOOK -->

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

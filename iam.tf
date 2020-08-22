# ### MAIN ACCOUNT - START
resource "aws_iam_service_linked_role" "config" {
  count            = var.master ? 1 : 0
  aws_service_name = "config.amazonaws.com"
}

resource "aws_iam_role" "aggregator" {
  count              = var.master ? 1 : 0
  name               = "customConfigAggregatorRole"
  path               = "/service-role/"
  description        = "AWS Organizations-related permissions for the AWS Config Aggregator"
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "customConfigAggregatorRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aggregator" {
  count      = var.master ? 1 : 0
  role       = aws_iam_role.aggregator[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations" # managed by AWS
}
# ### MAIN ACCOUNT - END


### SUBACCOUNT - START
resource "aws_iam_role" "default" {
  count              = var.master ? 0 : 1 # create only when var.master == false
  name               = "customConfigRoleForSubAccount"
  path               = "/service-role/"
  description        = "Add the necessary S3 permissions to the regular AWS Config ones"
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "customConfigRoleForSubAccount"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_bucket_permissions" {
  count       = var.master ? 0 : 1 # create only when var.master == false
  name        = "customS3BucketAccessForConfig"
  description = "Allows the necessary S3 permissions for AWS Config"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_bucket_permissions" {
  count      = var.master ? 0 : 1 # create only when var.master == false
  role       = aws_iam_role.default[count.index].name
  policy_arn = aws_iam_policy.s3_bucket_permissions[count.index].arn
}

resource "aws_iam_policy" "s3_objects_permissions" {
  count       = var.master ? 0 : 1 # create only when var.master == false
  name        = "customS3ObjectsAccessForConfig"
  description = "Allows the necessary S3 permissions for AWS Config"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_objects_permissions" {
  count      = var.master ? 0 : 1 # create only when var.master == false
  role       = aws_iam_role.default[count.index].name
  policy_arn = aws_iam_policy.s3_objects_permissions[count.index].arn
}

resource "aws_iam_role_policy_attachment" "custom_config_service_role_policy" {
  count      = var.master ? 0 : 1 # create only when var.master == false
  role       = aws_iam_role.default[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AWS_Config_Role" # managed by AWS
}
### SUBACCOUNT - END

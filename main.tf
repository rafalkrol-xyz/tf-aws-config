resource "aws_config_configuration_aggregator" "aggregator_account" {
  count = var.aggregator_account ? 1 : 0
  name  = "organization-config-aggregator"
  tags  = var.tags

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.aggregator[count.index].arn
  }
}

resource "aws_config_configuration_recorder" "default" {
  role_arn = var.aggregator_account ? aws_iam_service_linked_role.config[0].arn : aws_iam_role.default[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "default" {
  s3_bucket_name = var.s3_bucket_name

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_config_configuration_recorder.default]
}

resource "aws_config_configuration_recorder_status" "default" {
  name       = aws_config_configuration_recorder.default.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.default]
}

resource "aws_config_config_rule" "rule" {
  for_each                    = toset(var.rules)
  name                        = each.key
  description                 = "https://docs.aws.amazon.com/config/latest/developerguide/${each.key}.html"
  maximum_execution_frequency = "TwentyFour_Hours"
  tags                        = var.tags

  source {
    owner             = "AWS"
    source_identifier = replace(replace(upper(each.key), "-", "_"), "CLOUDTRAIL", "CLOUD_TRAIL") # change kebab-case into SCREAMING_SNAKE_CASE and CLOUDTRAIL into CLOUD_TRAIL
  }

  depends_on = [aws_config_configuration_recorder.default]
}

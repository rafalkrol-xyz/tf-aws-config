variable "s3_bucket_name" {
  description = "After the terraform docs: 'The name of the S3 bucket used to store the configuration history.'"
  type        = string
}

variable "aggregator_account" {
  description = "A flag indicating the aggregator_account account. NB only one per organization is permitted"
  type        = bool
  default     = false
}

variable "rules" {
  description = "A list of of AWS Config Managed Rules to be applied. Must be one of the following: https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resources that support the use of them"
  type        = map(string)
  default     = null
}

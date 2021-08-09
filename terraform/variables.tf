variable "projectname" {
  type = string
  description = "Projectname will be prepended to bucketnames. No underscores"
}
variable "source_bucketname" {
  type = string
  default = "-source-dataset-001"
}
variable "athena_bucketname" {
  type = string
  default = "-athena-results-001"
}
variable "glue_scripts_bucketname" {
  type = string
  default = "-glue-scripts-001"
}

variable "glue_role_name" {
  type = string
  default = "glue_processor_terraform"
}
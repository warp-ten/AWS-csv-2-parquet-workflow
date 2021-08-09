resource "aws_athena_workgroup" "workgroup" {
  name = var.projectname
  force_destroy = true
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.projectname}-${var.athena_bucketname}/"
    }
  }
}

resource "aws_athena_named_query" "foo" {
  name      = "main_query"
  workgroup = aws_athena_workgroup.workgroup.id
  database  = aws_glue_catalog_database.converted_parquet_catalog_database.name
  #table name can be found in the script thats uploaded in the S3.tf file. Extention is removed after conversion. 
  query     = replace("SELECT * FROM ${var.projectname}","-","_")
}
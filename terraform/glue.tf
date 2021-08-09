## CATALOG DATABASE RAWDATA ##
resource "aws_glue_catalog_database" "rawdata_glue_catalog_database" {
  name ="${var.projectname}_rawdata"
}

## CREATE RAWDATA CRAWLER ##
resource "aws_glue_crawler" "crawl_rawdata" {
  database_name = aws_glue_catalog_database.rawdata_glue_catalog_database.name
  name          = "${var.projectname}_rawdata_crawler"
  role = aws_iam_role.glue_role.arn
  s3_target {
    path = "s3://${aws_s3_bucket.etl_source_bucket.id}/rawdata/"
  }
}

### JOB CONVERT CSV TO PARQUET ###
resource "aws_glue_job" "convert_csv2parquet" {
  for_each = fileset("../datasets/","*")
  #name     = lower("${trim(each.value, ".csv")}_csv2parquet")
  name     = lower("${replace(each.value,".csv","_")}csv2parquet")
  role_arn = aws_iam_role.glue_role.arn
  glue_version = "2.0"
  worker_type = "G.1X"
  number_of_workers = 10
  command {
    python_version = 3
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.id}/${lower(replace(each.value,".","_"))}2parquet.py"
  }
  default_arguments = {
    "--job-language" = "python"
  }
}

## CATALOG DATABASE CONVERTED PARQUET DATA ##
resource "aws_glue_catalog_database" "converted_parquet_catalog_database" {
  name ="${var.projectname}_converted2parquet"
}

## CREATE CONVERTED PARQUET DATA CRAWLER ##
resource "aws_glue_crawler" "crawl_converted2parquet_data" {
  database_name = aws_glue_catalog_database.converted_parquet_catalog_database.name
  name          = "${var.projectname}_converted2parquet_crawler"
  role = aws_iam_role.glue_role.arn
  #This location is also in the script uploaded in the S3.tf file. (search for "output_location")
  s3_target {
    path = "s3://${var.projectname}-${var.source_bucketname}/converted2parquet/"
  }
### UNCOMMENT IF YOU WANT CRAWLER TO ATTEMPT TO COMBINE SCHEMAS
#   configuration = <<EOF
# {
#   "Version":1.0,
#   "Grouping": {
#     "TableGroupingPolicy": "CombineCompatibleSchemas"
#   }
# }
# EOF
}


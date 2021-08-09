# CREATE SOURCE DATASET BUCKET #
resource "aws_s3_bucket" "etl_source_bucket" {
  bucket = lower("${var.projectname}-${var.source_bucketname}")
  acl    = "private"
  force_destroy = true
  tags = {
    Name    = "${var.projectname}-${var.source_bucketname}"
  }
}
# UPLOAD "datasets" DIRECTORY TO BUCKET #
resource "aws_s3_bucket_object" "source_dataset" {
  for_each = fileset("../datasets/","*")
  bucket = aws_s3_bucket.etl_source_bucket.id
  key    = lower("rawdata/${replace(each.value," ","_")}")
  source = "../datasets/${each.value}"
  etag = filemd5("../datasets/${each.value}")
}

## CREATE ATHENA RESULTS BUCKET ##
resource "aws_s3_bucket" "athena_results_bucket" {
  bucket = "${var.projectname}-${var.athena_bucketname}"
  acl    = "private"
  force_destroy = true
  tags = {
    Name    = "${var.projectname}-${var.athena_bucketname}"
  }
}

### CREATE GLUE SCRIPTS BUCKET ###
resource "aws_s3_bucket" "glue_scripts_bucket" {
  bucket = "${var.projectname}-${var.glue_scripts_bucketname}"
  acl    = "private"
  force_destroy = true
}

### UPLOAD CSV2PARQUET PYTHON SCRIPT ###
resource "aws_s3_bucket_object" "csv2parquet_script" {
  for_each = fileset("../datasets/","*")
  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key = "${lower(replace(each.value,".","_"))}2parquet.py"
  content     = <<EOT
import sys
import datetime
import re
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
glueContext = GlueContext(SparkContext.getOrCreate())
job = Job(glueContext)

## DONT FORGET TO PUT IN YOUR INPUT AND OUTPUT LOCATIONS BELOW.
your_database_name = "${aws_glue_catalog_database.rawdata_glue_catalog_database.name}"
your_table_name = "${lower(replace(replace(each.value," ","_"),".","_"))}"
##This output is referenced in parquet data crawler (glue.tf)
output_location = "s3://${var.projectname}-${var.source_bucketname}/converted2parquet/${lower(replace(replace(each.value," ","_"),".csv","_parquet"))}"

job.init("byod-workshop" + str(datetime.datetime.now().timestamp()))

#load our data from the catalog that we created with a crawler
dynamicF = glueContext.create_dynamic_frame.from_catalog(
    database = your_database_name,
    table_name = your_table_name,
    transformation_ctx = "dynamicF")

# invalid characters in column names are replaced by _
df = dynamicF.toDF()
def canonical(x): return re.sub("[ ,;{}()\n\t=]+", '_', x.lower())
renamed_cols = [canonical(c) for c in df.columns]
df = df.toDF(*renamed_cols)

# write our dataframe in parquet format to an output s3 bucket
df.write.mode("overwrite").format("parquet").save(output_location)

job.commit()
  EOT
}
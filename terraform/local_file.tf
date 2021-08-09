## CREATE PYTHON SCRIPT WITH RESOURCE INFO ##
resource "local_file" "glue_script_csv2parquet" {
  for_each = fileset("../datasets/","*")

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
      your_table_name = "${lower(replace(each.value,".","_"))}"
      output_location = "s3://${var.source_bucketname}/job-convert2parquet/${var.projectname}"

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
  filename = "../csv2parquet.py"
} 


# resource "local_file" "glue_script" {
  
# }
#   value = <<EOT
#     import sys
#     import datetime
#     import re
#     from awsglue.transforms import *
#     from awsglue.utils import getResolvedOptions
#     from pyspark.context import SparkContext
#     from awsglue.context import GlueContext
#     from awsglue.job import Job
#     glueContext = GlueContext(SparkContext.getOrCreate())
#     job = Job(glueContext)

#     ## DONT FORGET TO PUT IN YOUR INPUT AND OUTPUT LOCATIONS BELOW.
#     your_database_name = "${aws_glue_catalog_database.rawdata_glue_catalog_database.name}"
#     your_table_name = "${var.source_dataset_name}_${var.source_dataset_type}"
#     output_location = "s3://${var.source_bucketname}/job-convert2parquet/${var.source_dataset_name}"

#     job.init("byod-workshop" + str(datetime.datetime.now().timestamp()))

#     #load our data from the catalog that we created with a crawler
#     dynamicF = glueContext.create_dynamic_frame.from_catalog(
#         database = your_database_name,
#         table_name = your_table_name,
#         transformation_ctx = "dynamicF")

#     # invalid characters in column names are replaced by _
#     df = dynamicF.toDF()
#     def canonical(x): return re.sub("[ ,;{}()\n\t=]+", '_', x.lower())
#     renamed_cols = [canonical(c) for c in df.columns]
#     df = df.toDF(*renamed_cols)

#     # write our dataframe in parquet format to an output s3 bucket
#     df.write.mode("overwrite").format("parquet").save(output_location)

#     job.commit()
# EOT
# }

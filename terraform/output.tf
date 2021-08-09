# output "glue_jobnames" {
#   description = "Names of the jobs created bases on the amount of files in the dataset directory"
#   value = aws_glue_job.convert_csv2parquet
# }

# output "glue_jobnames_set" {
#   description = "Names of the jobs created bases on the amount of files in the dataset directory"
#   value = toset([for i in aws_glue_job.convert_csv2parquet : i.name])
# }

# output "jobnames_map" {
#   value = tomap({for i, x in aws_glue_job.convert_csv2parquet : i => x.name
#   })
# }


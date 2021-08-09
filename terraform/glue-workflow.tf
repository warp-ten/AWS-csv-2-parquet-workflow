locals {
  jobs = aws_glue_job.convert_csv2parquet
}
resource "aws_glue_workflow" "csv2parquet" {
  depends_on = [
    aws_s3_bucket_object.csv2parquet_script,
    aws_glue_crawler.crawl_converted2parquet_data,
    aws_s3_bucket_object.source_dataset
  ]
  name = "csv2parquet_${var.projectname}"
}

resource "aws_glue_trigger" "on_demand_trigger" {
  name          = "on_demand"
  type          = "ON_DEMAND"
  #enabled = true
  workflow_name = aws_glue_workflow.csv2parquet.name

  actions {
    crawler_name = aws_glue_crawler.crawl_rawdata.name
  }
}

resource "aws_glue_trigger" "convert2parquet" {
  name          = "trigger-csv2parquet"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.csv2parquet.name
  predicate {
    conditions {
      crawler_name = aws_glue_crawler.crawl_rawdata.name
      crawl_state    = "SUCCEEDED"
    }
  }
  dynamic "actions" {
    for_each = local.jobs
    content {
      job_name = actions.value["name"]
    }
  }
}

resource "aws_glue_trigger" "crawl_convertedparquet" {
  name          = "trigger-crawl_convertedparquet"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.csv2parquet.name
  predicate {
    dynamic "conditions" {
      for_each = local.jobs
      content {
      job_name = conditions.value["name"]
      state = "SUCCEEDED"
      }
    }
  }
  actions {
    crawler_name = aws_glue_crawler.crawl_converted2parquet_data.name
  }
}
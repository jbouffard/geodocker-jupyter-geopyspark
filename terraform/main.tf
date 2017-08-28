# Marks AWS as a resource provider.
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# `aws_emr_cluster` is built-in to Terraform. We name ours `emr-spark-cluster`.
resource "aws_emr_cluster" "emr-spark-cluster" {
  name          = "GeoNotebook + GeoPySpark Cluster"
  release_label = "emr-5.7.0"

  # This it will work if only `Spark` is named here, but booting the cluster seems
  # to be much faster when `Hadoop` is included. Ingests, etc., will succeed
  # even if `Hadoop` is missing here.
  applications = ["Hadoop", "Spark", "Ganglia", "Zeppelin"]

  ec2_attributes {
    key_name         = "${var.key_name}"
    instance_profile = "EMR_EC2_DefaultRole"
  }

  # MASTER group must have an instance_count of 1.
  # `xlarge` seems to be the smallest type they'll allow (large didn't work).
  instance_group {
    bid_price      = "0.05"
    instance_count = 1
    instance_role  = "MASTER"
    instance_type  = "m3.xlarge"
    name           = "geopyspark-master"
  }

  instance_group {
    bid_price      = "0.05"
    instance_count = 2
    instance_role  = "CORE"
    instance_type  = "m3.xlarge"
    name           = "geopyspark-core"
  }

  # Location to dump logs
  log_uri = "${var.s3_uri}"

  # These can be altered freely, they don't affect the config.
  tags {
    name = "geodocker"
    role = "EMR_DefaultRole"
  }

  # This is the effect of `aws emr create-cluster --use-default-roles`.
  service_role = "EMR_DefaultRole"
}

output "emr-id" {
  value = "${aws_emr_cluster.emr-spark-cluster.id}"
}

output "emr-master" {
  value = "${aws_emr_cluster.emr-spark-cluster.master_public_dns}"
}

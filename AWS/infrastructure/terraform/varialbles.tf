variable "project" {
  description = "The name of this project"
  default     = "Arcus"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnetaz1" {
  type = "map"

  default = {
    eu-central-1 = "eu-central-1a"
  }
}

variable "subnetaz2" {
  type = "map"

  default = {
    eu-central-1 = "eu-central-1b"
  }
}

variable "subnetaz3" {
  type = "map"

  default = {
    eu-central-1 = "eu-central-1c"
  }
}

variable "public_subnet_cidr1" {
  default = "10.0.1.0/24"
}

variable "public_subnet_cidr2" {
  default = "10.0.2.0/24"
}

variable "public_subnet_cidr3" {
  default = "10.0.3.0/24"
}

variable "public_subnet_cidr_emr" {
  default = "10.0.4.0/24"
}

variable "key_name" {
  description = "The name of the key to user for ssh access"
  default     = "eu-central-1_KP"
}

variable "amisize_grib_parse_instance" {
  default = "t2.micro"
}

variable "amisize_oracle_instance" {
  default = "t3.medium"
}

variable "amisize_emr_master_instance" {
  default = "m4.large"
}

variable "amisize_emr_core_instance" {
  default = "m4.large"
}

variable "arcus_internal_bucket_name" {
  default = "devel-arcus-internal"
}

variable "eccodes_path" {
  description = "path to eccodes software"
  default = "software/eccodes"
}

variable "eccodes_version" {
  description = "eccodes source version. Must be equal to the tar.gz file without extension."
  default = "eccodes-2.4.0-Source"
}

variable "min_grib_parse_instances" {
  default = "1"
}

variable "max_grib_parse_instances" {
  default = "1"
}

variable "create_emr_cluster" {
  description = "If set to 1, create an EMR Cluster"
  default = false
}

variable "create_oracle_instance" {
  description = "If set to 1, create an Oracle DB Server instance"
  default = false
}

variable "create_grib_parse_cluster" {
  description = "If set to 1, create a grib parse cluster"
  default = false
}

variable "create_geoserver_cluster" {
  description = "If set to 1, create a geoserver cluster"
  default = false
}

variable "deploy_lambda_convert_grib2geotiff" {
  description = "If set to 1, deploy grib2geotiff lambda"
  default = false
}
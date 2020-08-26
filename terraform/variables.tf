# variables.tf

variable "domain" {}
variable "cluster_name" {}

variable "versions" {
  default = {
    "psql"       = "v1.0.0"
    "solr"       = "v1.0.1"
    "image"      = "v1.0.1"
    "mgmt"       = "v2.10.0"
    "blacklight" = "v1.11.0"
    "mft"        = "v2.0.1"

  }
}

variable "app_ports" {
  default = {
    "psql"       = 5432
    "solr"       = 8983
    "mft"        = 80
    "mgmt"       = 3001
    "blacklight" = 3000
    "image"      = 8182
  }
}

variable "images" {
  default = {
    "psql"       = "yalelibraryit/dc-postgres:$${var.versions[psql]}"
    "solr"       = "yalelibraryit/dc-solr:$${var.versions[solr]}"
    "image"      = "yalelibraryit/dc-iiif-cantaloupe:$${var.versions[image]}"
    "mft"        = "yalelibraryit/dc-iiif-manifest:$${var.versions[iiif_manifest]}"
    "mgmt"       = "yalelibraryit/dc-management:$${var.versions[management]}"
    "blacklight" = "yalelibraryit/dc-blacklight:$${var.versions[blacklight]}"
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "ecs_task_execution_role_name" {
  default = "ecsTaskExecutionRole"
}

variable "az_count" {
  default = "2"
}

variable "app_count" {
  default = 1
}


variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "2048"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "8192"
}


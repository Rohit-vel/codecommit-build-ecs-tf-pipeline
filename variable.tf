variable "service_name" {
  type    = string
  default = "ecr-ecs-cp"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  access_key = ""
  secret_key = ""
  region     = var.aws_region
}

variable "ecs_key_pair_name" {
  default = ""
}

variable "aws_account_id" {
  default = ""
}


variable "container_port" {
  default = "8080"
}

variable "memory_reserv" {
  default = 100
}

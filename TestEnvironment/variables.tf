variable "project" {}

variable "credentials_file" {}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-c"
}

variable "cluster_user" {
  type = string
}

variable "bastion_user" {
  type = string
}

variable "worker_count" {
  default = 2
}

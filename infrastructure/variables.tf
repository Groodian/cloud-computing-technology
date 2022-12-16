variable "project" {}

variable "credentials_file" {}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-c"
}

variable "user" {
  type = string
}

variable "email" {
  type = string
}

variable "worker_count" {
  default = 2
}

variable "project" {}

variable "credentials_file" {}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "user" {
  type = string
}

variable "email" {
  type = string
}

variable "privatekeypath" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "publickeypath" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
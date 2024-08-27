variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_instance_type" {
  type = string
  default = "t3.medium"
}
variable "small_instance" {
  type = string
  default = "t2.small"
}
locals {
  instances = ["control_plane", "node_1", "node_2"]
}
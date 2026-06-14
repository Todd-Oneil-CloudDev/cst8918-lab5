variable "labelPrefix" {
  description = "prefix to be added to all resources"
  type = string
  default = "onei0240"
}

variable "region" {
  description = "region resources should be deployed"
  default = "canadacentral"
}

variable "admin_username" {
  description = "administrator"
  default = "todd"
}
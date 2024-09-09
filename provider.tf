terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

## Alternative way to setup the OCI provider for Terraform
# provider "oci" {
#    region = "us-phoenix-1"
#    tenancy_ocid = "${var.tenancy_ocid}"
#    user_ocid = "${var.user_ocid}"
#    fingerprint = "${var.fingerprint}"
#    private_key_path = "${var.private_key_path}"
# }
# variable "fingerprint" {
#   default = "11:26:47:99:a3:fe:09:0f:08:32:86:5b:4c:33:fb:78"
#   type    = string
# }
#
# variable "private_key_path" {
#   default = "~/.oci/oci_api_key.pem"
#   type    = string
# }
#
# variable "user_ocid" {
#   description = "Your OCI IAM User OCID"
#   default     = "ocid1.user.oc1..aaaaaaaabfor2ujk6u4otberxggg2oauclotunxtyh6sam44exev66g5w6nq"
#   type        = string
# }


variable "config_file_profile" {
  type = string
  default = "DEFAULT"
}

provider "oci" {
  region              = var.region
  config_file_profile = var.config_file_profile
}

provider "oci" {
  region              = lookup(local.region_map_key_fname, data.oci_identity_tenancy.tenancy.home_region_key)
  alias               = "home"
  config_file_profile = var.config_file_profile
}


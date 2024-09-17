terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}

provider "oci" {
  region           = var.region
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

provider "oci" {
  alias            = "home"
  region           = lookup(local.region_map_key_fname, data.oci_identity_tenancy.tenancy.home_region_key)
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}



## Alternative way to setup the OCI provider for Terraform
# provider "oci" {
#   region              = var.region
#   config_file_profile = "DEFAULT"
# }

# provider "oci" {
#   region              = lookup(local.region_map_key_fname, data.oci_identity_tenancy.tenancy.home_region_key)
#   alias               = "home"
#   config_file_profile = "DEFAULT"
# }


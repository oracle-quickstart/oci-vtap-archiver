variable "tenancy_ocid" {
  description = "Your Tenancy OCID"
  type        = string
}

variable "region" {
  description = "OCI region where resources are to be created/maintained, full name like us-ashburn-1"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment where resources are to be created & maintained"
  type        = string
}


variable "bucket_name" {
  description = "Your object storage bucket's name for creation. This is is where your pcap files from VTAP will archived for later access"
  default     = "archival_bkt_pcaps"
  type        = string
}

variable "vcn_cidr" {
  description = "IPv4 CIDR for the VCN where NLB, VMs for VTAP Source and VTAP Sink nodes, jumpbox/fileserver node will reside"
  default     = "10.0.0.0/16"
  type        = string
}
variable "pvt_subnet_cidr_vtap_src_nodes" {
  description = "IPv4 CIDR for the private subnet within the VCN where compute nodes acting as source for VTAP will reside, should be within the CIDR of VCN. These compute act as client downloading file over HTTP from server"
  default     = "10.0.1.0/24"
  type        = string
}

variable "pvt_subnet_cidr_sink_nodes" {
  description = "IPv4 CIDR for the private subnet within the VCN where NLB and VMs to capture VTAP will reside, should be within the CIDR of VCN"
  default     = "10.0.2.0/24"
  type        = string
}

variable "pub_subnet_cidr_jumpbox_plus_http_file_server" {
  description = "IPv4 CIDR for the public subnet within the VCN where VM acting as both jumpbox(for your access) & simple HTTP file server for VTAP source compute nodes; Should be within the CIDR of VCN. This VM will be used as source for the VTAP"
  default     = "10.0.0.0/24"
  type        = string
}

variable "vtap_source_count" {
  default     = "3"
  description = "Number of instances to act as VTAP source nodes, HTTP traffic originating from these nodes will be mirrored by VTAP"
  type        = number
}
variable "vtap_sink_count" {
  default     = "2"
  description = "Number of 'VTAP sink' instances behind target NLB(of VTAP). These instances will do packet capture and upload it to a bucket"
  type        = number
}

variable "instance_shape" {
  default     = "VM.Standard.A1.Flex"
  description = "Shape for instances, same for both VTAP source and VTAP Sink nodes"
  type        = string
}

variable "instance_ocpus" {
  default     = 3
  description = "OCPU count for instances, same for both: VTAP source nodes, VTAP sink nodes"
  type        = number
}

variable "instance_memory_in_gbs" {
  default     = 12
  description = "RAM size for instances, same for all: VTAP source nodes, VTAP sink nodes"
  type        = number
}

variable "ssh_public_key" {
  description = "Full path to the SSH public key file. Used to login to instance with corresponding private key. Will be used for all VMs. In production, use OCI Bastion as jumpbox."
  type        = string
}

variable "vxlan_id" {
  default     = "3000"
  type        = string
  description = "VXLAN ID aka VNI for vtap capture. Arbitrary positive number, optional to specify. Later needs to be specified in capture commands like tcpdump or tshark, for filtering. In this setup, we are using same VNI for VTAP of all source nodes"
}

variable "decap_yes_or_no" {
  default     = "YES"
  type        = string
  description = "Pass YES(or yes) if you want VTAP captured traffic to be decapsulated to give you original inner packets as seen by sources of the VTAP. For any other value or absence thereof, decapsulation won't be performed."
}

# data
locals {
  region_map_key_fname = { for r in data.oci_identity_regions.regions.regions : r.key => r.name }
}

locals {
  region_code_fanme_key = { for r in data.oci_identity_regions.regions.regions : r.name => r.key }
}

locals {
  region_key = lookup(local.region_code_fanme_key, var.region)
}


data "oci_identity_regions" "regions" {

}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "ad_list" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "oracle_linux_images" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape  #"VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_objectstorage_namespace" "object_storage_namespace" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_compartment" "compartment" {
    id = var.compartment_ocid
}



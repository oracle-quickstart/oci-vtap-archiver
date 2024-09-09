resource oci_objectstorage_bucket pcap_archival_bucket {
  access_type    = "NoPublicAccess"
  auto_tiering   = "InfrequentAccess"
  compartment_id = var.compartment_ocid
  name                  = var.bucket_name
  namespace             = data.oci_objectstorage_namespace.object_storage_namespace.namespace
  storage_tier          = "Standard"
  versioning            = "Disabled"
}
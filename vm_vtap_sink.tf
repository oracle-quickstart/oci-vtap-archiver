resource "oci_core_instance" "vm_vtap_sink" {

  count               = var.vtap_sink_count
  availability_domain = data.oci_identity_availability_domains.ad_list.availability_domains[count.index % length(data.oci_identity_availability_domains.ad_list.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = "vm_vtap_sink${count.index}"

  shape = var.instance_shape
 
  shape_config {
    memory_in_gbs             = var.instance_memory_in_gbs
    ocpus                     = var.instance_ocpus
  }

  source_details {
    source_type = "image"
    source_id = data.oci_core_images.oracle_linux_images.images[0].id
  }

  freeform_tags = {
    "vtapsyncvm" = "true"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(templatefile("${path.root}/cloud_init/vtap_sink.yml", { pcap_archival_bucket_name  = "${var.bucket_name}", vxlan_id  = "${var.vxlan_id}", decap_yes_no = "${var.decap_yes_or_no}"}))
  }


  create_vnic_details {
    assign_public_ip       = "false"
    display_name           = "primary_vnic"
    hostname_label         = "vmsinkvnic${count.index}"
    subnet_id              = oci_core_subnet.vtap_sink_pvt_subnet.id
  }
  state = "RUNNING"
  depends_on = [ oci_identity_policy.bucket_put_policy, oci_objectstorage_bucket.pcap_archival_bucket ]
}

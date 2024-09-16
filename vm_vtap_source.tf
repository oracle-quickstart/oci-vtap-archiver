resource "oci_core_instance" "vm_vtap_source" {
  count               = var.vtap_source_count
  availability_domain = data.oci_identity_availability_domains.ad_list.availability_domains[count.index % length(data.oci_identity_availability_domains.ad_list.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = "vm_vtap_source${count.index}"

  shape = var.instance_shape
 
  shape_config {
    memory_in_gbs             = var.instance_memory_in_gbs
    ocpus                     = var.instance_ocpus
  }

  source_details {
    source_type = "image"
    source_id = data.oci_core_images.oracle_linux_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
    user_data           = base64encode(templatefile("${path.root}/cloud_init/vtap_source.yml", { http_file_server_ip  = "${oci_core_instance.vm_jumpbox_fileserver.private_ip}"}))
  }

  create_vnic_details {
    assign_public_ip       = "false"
    display_name           = "vtap_src_vnic${count.index}"
    hostname_label         = "vmvtapsource${count.index}"
    subnet_id              = oci_core_subnet.vtap_src_pvt_subnet.id
  }
  
  state = "RUNNING"
}

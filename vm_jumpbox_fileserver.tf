resource "oci_core_instance" "vm_jumpbox_fileserver" {
  availability_domain = data.oci_identity_availability_domains.ad_list.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "vm_jumpbox_fileserver"

  shape = var.instance_shape
 
  shape_config {
    memory_in_gbs             = 6
    ocpus                     = 1
  }

  source_details {
    source_type = "image"
    source_id = data.oci_core_images.oracle_linux_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.root}/cloud_init/jumpbox_fileserver.yml"))
  }

  create_vnic_details {
    display_name           = "jumpbox"
    hostname_label         = "jumpboxplusfileserver"
    subnet_id              = oci_core_subnet.jumpbox_and_fileserver_public_subnet.id
  }
  
  state = "RUNNING"
}

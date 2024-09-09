resource "oci_core_capture_filter" "capture_filter" {
  compartment_id = var.compartment_ocid

  display_name = "cf_vtap"
  filter_type  = "VTAP"

  vtap_capture_filter_rules {
    protocol    = "6" #tcp
    rule_action = "INCLUDE"
    tcp_options {
      source_port_range {
        min = "80"
        max = "80"
      }
      destination_port_range {
        min = "15555"
        max = "15555"
      }
    }
    traffic_direction = "INGRESS"
    source_cidr = oci_core_subnet.jumpbox_and_fileserver_public_subnet.cidr_block
    destination_cidr  = oci_core_subnet.vtap_src_pvt_subnet.cidr_block
  }

  vtap_capture_filter_rules {
    protocol    = "6"
    rule_action = "INCLUDE"
    tcp_options {
      source_port_range {
        min = "15555"
        max = "15555"
      }
      destination_port_range {
        min = "80"
        max = "80"
      }
    }
    traffic_direction = "EGRESS"
    source_cidr = oci_core_subnet.vtap_src_pvt_subnet.cidr_block
    destination_cidr  = oci_core_subnet.jumpbox_and_fileserver_public_subnet.cidr_block
  }
}

data "oci_core_vnic_attachments" "vm_vtap_src_vnic" {
  count          = var.vtap_source_count
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.vm_vtap_source[count.index].id
}

resource "oci_core_vtap" "vtap" {
  count             = var.vtap_source_count
  capture_filter_id = oci_core_capture_filter.capture_filter.id
  compartment_id    = var.compartment_ocid

  display_name           = "vtap_demo${count.index}"
  encapsulation_protocol = "VXLAN"

  source_id   = data.oci_core_vnic_attachments.vm_vtap_src_vnic[count.index].vnic_attachments[0]["vnic_id"]
  source_type = "VNIC"

  target_id                = oci_network_load_balancer_network_load_balancer.nlb_for_vtap.id
  target_type              = "NETWORK_LOAD_BALANCER"
  vcn_id                   = oci_core_vcn.vtap_vcn.id
  vxlan_network_identifier = var.vxlan_id

  # This gives the same priority to VTAP traffic as your regular VCN traffic. If not needed set as "DEFAULT" instead.
  traffic_mode = "DEFAULT"

  # VTAP has to be enabled manually from OCI Web Console
  is_vtap_enabled = "false"

  # Depending on your usecase and for efficient ingestion of mirrored traffic, you might want to just include headers.
  # if yes, feel free to reduce max_packet_size accordingly
  max_packet_size = "9000" 
}

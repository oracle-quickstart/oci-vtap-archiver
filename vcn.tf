resource oci_core_vcn vtap_vcn {
  cidr_blocks = [
    var.vcn_cidr,
  ]
  compartment_id = var.compartment_ocid
  display_name = "vcn_vtap_setup"
  dns_label    = "vcnvtapsetup"
}

resource oci_core_service_gateway service_gateway {
  compartment_id = var.compartment_ocid
  display_name = "service_gateway"
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_internet_gateway internet_gateway {
  compartment_id = var.compartment_ocid
  display_name = "internet_gateway"
  enabled      = "true"
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_subnet vtap_src_pvt_subnet {
  cidr_block     = var.pvt_subnet_cidr_vtap_src_nodes
  compartment_id = var.compartment_ocid

  display_name    = "vtap_src_pvt_subnet"
  dns_label       = "vtapsrcpvtsb"

  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.all_pvt_sb_rt.id 
  security_list_ids = [
    oci_core_security_list.vtap_src_sb_sl.id,
  ]
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_security_list vtap_src_sb_sl {
  compartment_id = var.compartment_ocid

  display_name = "vtap_src_sb_sl"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }

  ingress_security_rules {
    description = "For ssh from public subnet jumpbox"
    protocol    = "6" #TCP
    source      = oci_core_subnet.jumpbox_and_fileserver_public_subnet.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_subnet vtap_sink_pvt_subnet {
  cidr_block     = var.pvt_subnet_cidr_sink_nodes
  compartment_id = var.compartment_ocid

  display_name    = "vtap_sink_pvt_subnet"
  dns_label       = "vtapsinkpvtsb"

  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.all_pvt_sb_rt.id 
  security_list_ids = [
    oci_core_security_list.vtap_sink_sb_sl.id,
  ]
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_security_list vtap_sink_sb_sl {
  compartment_id = var.compartment_ocid

  display_name = "vtap_sink_sb_sl"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }

  ingress_security_rules {
    description = "for VTAP (VxLAN/UDP) mirror traffic, stateless for high performance"
    protocol    = "17" # UDP
    source      = var.pvt_subnet_cidr_vtap_src_nodes
    source_type = "CIDR_BLOCK"

    stateless   = "true"
    udp_options {
      max = "4789"
      min = "4789"
    }
  }
  ingress_security_rules {
    description = "for Backend Server's Health Check by NLB, & for ssh from public subnet jumpbox"
    protocol    = "6" #TCP
    source      = oci_core_subnet.jumpbox_and_fileserver_public_subnet.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
    ingress_security_rules {
    description = "for Backend Server's Health Check by NLB, & for ssh from public subnet jumpbox"
    protocol    = "6" #TCP
    source      = var.pvt_subnet_cidr_sink_nodes # for Health check from NLB from the same subnet
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_route_table all_pvt_sb_rt {
  compartment_id = var.compartment_ocid

  display_name = "rt_all_pvt_sb"
  route_rules {
    description       = "for access to Object Storage and Yum repo access, region specific OSN CIDR"
   
    # following spits out "all-<3 letter region code>-services-in-oracle-services-network"
    destination       =  data.oci_core_services.all_services.services[0].cidr_block 
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_subnet jumpbox_and_fileserver_public_subnet {
  cidr_block     = var.pub_subnet_cidr_jumpbox_plus_http_file_server
  compartment_id = var.compartment_ocid

  display_name    = "jumpbox_and_fileserver_public_subnet"
  dns_label       = "jumpboxfspubsb"
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_route_table.jumpbox_and_fileserver_pb_sb_rt.id
  security_list_ids = [
    oci_core_security_list.public_sb_sl.id,
  ]
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_security_list public_sb_sl {
  compartment_id = var.compartment_ocid

  display_name = "vtap_pub_sb_sl"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }

  ingress_security_rules {
    description = "for ssh to public subnet computes"
    protocol    = "6" #TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    description = "for VTAP source nodes to download file over HTTP file server"
    protocol    = "6" #TCP
    source      = var.pvt_subnet_cidr_vtap_src_nodes # only private subnet of VTAP sources can access
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "80"
      min = "80"
    }
  }
  vcn_id = oci_core_vcn.vtap_vcn.id
}

resource oci_core_route_table jumpbox_and_fileserver_pb_sb_rt {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.vtap_vcn.id
  display_name = "jumpbox_and_fileserver_pb_sb_rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

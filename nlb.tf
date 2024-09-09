resource "oci_network_load_balancer_network_load_balancer" "nlb_for_vtap" {
  compartment_id = var.compartment_ocid
  display_name   = "nlb_vtap_target"
  is_private     = "true"
  nlb_ip_version = "IPV4"
  subnet_id      = oci_core_subnet.vtap_sink_pvt_subnet.id
}

resource "oci_network_load_balancer_listener" "listener_for_vtap" {
  default_backend_set_name = oci_network_load_balancer_backend_set.backendset.name
  ip_version               = "IPV4"
  is_ppv2enabled           = "false"
  name                     = "listener_for_vtap_4789"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_for_vtap.id
  port                     = "4789"
  protocol                 = "UDP"
}

resource "oci_network_load_balancer_backend_set" "backendset" {
  health_checker {
    interval_in_millis = "10000"
    port               = "22"
    protocol           = "TCP"
    request_data       = ""
    response_data      = ""
    retries            = "3"
    timeout_in_millis  = "3000"
  }
  ip_version                  = "IPV4"
  is_fail_open                = "true"
  is_instant_failover_enabled = "true"
  name                        = "backendset_of_vm_vtap_capture"
  network_load_balancer_id    = oci_network_load_balancer_network_load_balancer.nlb_for_vtap.id
  policy                      = "FIVE_TUPLE" # you can use TWO_TUPLE too, since any VXLAN packet from any VTAP src, will only have source IP which will be different
  is_preserve_source          = true
}

resource "oci_network_load_balancer_backend" "nlb_backend_server" {
  backend_set_name         = oci_network_load_balancer_backend_set.backendset.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_for_vtap.id
  port                     = "4789"
  count                    = var.vtap_sink_count
  target_id                = oci_core_instance.vm_vtap_sink[count.index].id
  name                     = "nlb_backend_server${count.index}"
}




output "vm_jumpboxhttp_public_ip" {
    description = "public ip vm_jumpbox_and_http_server"
    value = oci_core_instance.vm_jumpbox_fileserver.public_ip
}

output "vm_jumpboxhttp_private_ip" {
    description = "private ip vm_jumpbox_and_http_server"
    value = oci_core_instance.vm_jumpbox_fileserver.private_ip
}

output "vm_vtap_source" {
    description = "private ip of vm_vtap_source"
    value = oci_core_instance.vm_vtap_source[*].private_ip
}

output "nlb_pvt_ip" {
  description = "NLB private ip"
  value = oci_network_load_balancer_network_load_balancer.nlb_for_vtap.ip_addresses
}

output "vm_vtap_sink" {
    description = "private ip of vm_vtap_sink "
    value = oci_core_instance.vm_vtap_sink[*].private_ip
}

output "ocid_for_bucket_for_pcaps" {
  description = "ocid_for_bucket_for_pcaps"
  value = oci_objectstorage_bucket.pcap_archival_bucket.bucket_id
}




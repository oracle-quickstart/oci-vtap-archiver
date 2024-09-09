resource "oci_identity_dynamic_group" "bucket_uploader_vm_dg" {
    #Required
    compartment_id = var.tenancy_ocid
    provider = oci.home
    description = "DG for VM which upload captured packet to user specified bucket"
    matching_rule = " ALL {instance.compartment.id = '${var.compartment_ocid}'}" 
    name = "bkt_uploader_vm_dg"
}

resource "oci_identity_policy" "bucket_put_policy" {
    depends_on     = [oci_identity_dynamic_group.bucket_uploader_vm_dg]
    compartment_id = var.compartment_ocid
    provider = oci.home
    description = "Identity policy for DG for VM to allow upload captured packet to user specified bucket"
    name = "bkt_put_policy"

    statements = [
            "Allow dynamic-group bkt_uploader_vm_dg to read buckets in compartment '${data.oci_identity_compartment.compartment.name}' ",
            "Allow dynamic-group bkt_uploader_vm_dg to manage objects in compartment '${data.oci_identity_compartment.compartment.name}'  where any {request.permission='OBJECT_CREATE', request.permission='OBJECT_INSPECT', request.region = '${local.region_key}'}" 
    ]
}
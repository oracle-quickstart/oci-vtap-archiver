- [Archive VTAP Traffic to OCI Object Storage](#archive-vtap-traffic-to-oci-object-storage)
  - [Solution](#solution)
    - [Architecture](#architecture)
    - [Details](#details)
  - [Fine-Tuning](#fine-tuning)
  - [Deployment](#deployment)
    - [1. Using Resource Manager](#1-using-resource-manager)
    - [2. Locally from your dev-machine](#2-locally-from-your-dev-machine)
  - [Possible Improvements](#possible-improvements)
  - [Known Limitations](#known-limitations)
  - [Contact Author](#contact-author)


# Archive VTAP Traffic to OCI Object Storage
OCI Virtual Test Access Point, [VTAP](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/vtap.htm), is a network traffic mirroring service. It captures a copy of network traffic from a specified source, applies filters to focus on relevant data, and sends it to a target for analysis. This enables use cases such as network troubleshooting, security monitoring, network performance analysis, and compliance auditing.

For compliance or for troubleshooting elusive/intermittent network issues, you might prefer to archive your network traffic rather than perform continuous live monitoring. You can then selectively analyze the network capture of past production traffic as needed. For such scenarios, this solution demonstrates how to archive your mirrored traffic from the VTAP to an Object-Storage bucket in OCI.

The solution is self-contained. Terraform will set up all the resources required within your OCI tenancy.

## Solution 
### Architecture

<kbd><img src="images/diagram.png?raw=true" width="1250" /></kbd>

### Details
The Terraform configuration will create a VCN with three subnets: one public and two private. The public subnet will have a single host, which acts as both an HTTP file server and a jumpbox to access nodes in the two private subnets. 

One private subnet hosts nodes that download a dummy file from the HTTP file server to create HTTP traffic. These nodes act as sources for the VTAP, and their traffic is mirrored by the VTAP. We'll refer to these nodes as *VTAP Source* nodes. Each *VTAP Source* node has its own separate VTAP.

Another private subnet will contain a [Network Load Balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/home.htm) (NLB) that acts as the target for the VTAPs. The NLB will have backend nodes that perform network capture of the VTAP traffic as *pcap* files and archive them to a bucket. We call these nodes *VTAP Sink* nodes. The *VTAP Sink* nodes and NLB reside in the same private subnet. 

VTAP is configured with a *capture filter* to capture only network traffic of *HTTP GET* requests fired by these *VTAP Sources*, to the HTTP file server in our public subnet. Please see [vtap.tf](vtap.tf) for details on the *capture filter*. Specifically, the VTAP is set on the primary [VNIC](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/managingVNICs.htm) of the *VTAP Source* nodes. 

You can choose the region and compartment for your deployment. All resources will be created in the specified region and compartment. The Object Storage bucket to archive the *pcap* files will also be created for you. 

This solution is developed and tested only for IPv4 traffic. 

Please see [variables.tf](variables.tf) to view all the configurable parameters.

We assume you have the requisite OCI IAM permissions for the chosen compartment and region, to create all the necessary OCI resources for this deployment. For help with IAM permissions, please refer to [Common OCI Network IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/commonpolicies.htm#top).


## Fine-Tuning
* We use `tcpdump` to perform the traffic capture on *VTAP Sink* nodes. The `tcpdump` command is in the cloud-init script for [*VTAP Sink*](cloud_init/vtap_sink.yml#41) nodes. It creates a rotating buffer of 50 capture files in *pcap* format, each of size 10 MB. Another [script](cloud_init/vtap_sink.yml#62) picks up each *pcap* file, compresses it, renames it with packet capture duration timestamps, and uploads it to the bucket. After the upload, it deletes the local zip file. Hence, storage consumption on *VTAP Sink* nodes is capped at 500 MB. Feel free to fine-tune these parameters as per your requirements.

* VTAP traffic consists of the original packets "as seen" by the VTAP source, with VXLAN encapsulation. You can choose whether to decapsulate the VTAP traffic, leaving only the original packet. Decapsulation will reduce the storage needed for the *pcap* files. Please refer to cloud-init script for [*VTAP Sink*](cloud_init/vtap_sink.yml#41) nodes, for details on decapsulation with virtual VXLAN interface.

* Please adjust the size, shape, and count of *VTAP Sink* nodes depending on the volume of your mirrored traffic.

* If your traffic analysis only requires header information, you can set a lower value for `Max Packet Size` to say ~ 200 in [vtap.tf](vtap.tf). Note that `Max Packet Size` determines the size of the capture VTAP performs on the original packets on the *VTAP Source* and does not include any headers added by the VXLAN encapsulation.

* You can potentially have the *source* of your VTAP in any VCN that is peered to the VCN containing your NLB (acting as the target for VTAP). With a few tweaks, this solution can easily be adapted to your environment!

* You can check status VTAP capture service on your *VTAP Sink* nodes with standard `systemd` commands like `journalctl -u vtaparchiver.service`, or `systemctl status vtaparchiver.service`.

## Deployment
You have two easy options !

### 1. Using Resource Manager
This Quick Start uses [OCI Resource Manager](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) to make deployment easy. Please log into *OCI Web Console*, select appropriate region and compartment & then just click the button below:

[![Deploy to Oracle Cloud !](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-vtap-archiver/archive/main.zip)

The *OCI Web Console* will take you through setup of all the variables required for the deployment.


### 2. Locally from your dev-machine

1. Install Terraform
2. Access to Oracle Cloud Infastructure
3. Download or clone the repo to your local machine
  ```sh
  git clone git@github.com:oracle-quickstart/oci-vtap-archiver.git
  ```
4. Replace variable values in `local.tfvars.example` with values as applicable to your OCI tenancy and rename file to `local.tfvars`.
5. Run Terraform
  ```sh
  terraform init
  terraform plan -var-file=local.tfvars
  terraform apply -var-file=local.tfvars
  ```

> After deployment: Turn on VTAPs for each *VTAP Source* nodes
Please note that VTAPs can only be started on the *OCI Web Console*. After applying the Terraform configuration, you need to start all your VTAPs on the *OCI Web Console*, as shown below.

> <kbd><img src="images/start_vtap_on_console.png?raw=true" width="850"/></kbd>


## Possible Improvements
1. Using log-collectors like FluentBit, Vector may provide a better way to transfer network capture data to OCI Object Storage. FluentBit, Vector can handle backpressure and resume failed uploads from saved checkpoints.

    The pre-conditions for this would be: 
    * S3 API Compatibility needs to be enabled for OCI Object Storage to leverage output plugin for S3 of these log-collectors, and 
    * Network capture output should be in a text format like CSV or JSON. Please note `tshark` can output network capture in CSV or JSON but `tcpdump` can not. 

2. Using `tshark` for *pcapng* format. 

3. Splitting and merging the *pcap* files by *VTAP Source*. In current setup, a single *pcap* file on a *VTAP Sink* node might have captured traffic of multiple *VTAP Source* nodes. 

4. Packet Capture with PacketBeat and then analysis with [OCI OpenSearch Service](https://docs.oracle.com/en-us/iaas/Content/search-opensearch/home.htm)!

5. Support for IPv6.

## Known Limitations
1. If the `Max Packet Size` setting for VTAP is lower than the *max packet size* of packets in your mirrored traffic, and if you are using Wireshark, Wireshark will display `TCP Previous segment not captured` and `TCP ACKed unseen segment`. This is because Wireshark performs its *TCP Flow Analysis* based on the number of `bytes on the wire` recorded for captured packets. More details below. 

* For each packet in the *pcap* files `tcpdump` records count(`bytes on the wire`) it sees during the capture. 
* For most packets, `count(bytes on the wire)` < `length(original packet)`, as they get truncated before reaching `tcpdump` in VTAP itself is set to lower value of `Max Packet Size`. 
* Therefore, from the perspective of `tcpdump`, the VTAP truncated packet is the **full original packet**. 
* This occurs regardless of if VXLAN decapsulationis performed or not.
* This occurs regardless truncation at `tcpdump` command with its `snaplen` parameter.
* With `editcap`, it might be possible to correct the number of `bytes on the wire` in the *pcap* files using `IP Length` header field of the original packet, but I am yet to explore this. 
* For the curious, please refer to my [discussion](https://ask.wireshark.org/question/35512/tcp-warnings-already-truncated-mirrored-traffic/) with the Wireshark community.

2. If you are decapsulating the VTAP traffic of its VXLAN header and there is no trucation at VTAP for the mirrored traffic, you may see packets with lengths in the capture that are way above 9k. But max allowed MTU in OCI VCN is 9k! This happens when `generic receive offloading`(of Linux OS) is enabled on the network interface used for the capture. The interface merges multiple TCP segments and sends the aggregated TCP segment to the upper layer in one go to save on CPU cycles. You can turn it off with `ethtool -K <interface> gro off`. You might want to disable all offloading features of the network interface used for capturing.

3. At the time of reboots of *VTAP Sink* nodes, `pcap` capture files which are under *process* at that time, can get abodoned. These unfortunate `pcap` capture files will be not be reprocessed after reboots and will remain on the node till manually cleaned up. However, as `tcpdump` running on *VTAP Sink* node is configured as a `systemd` service, it will restart automatically after reboot and continue with the archival of the VTAP traffic. 

## Contact Author

* Mayur Raleraskar - feedback_oci_virtual_networking_us_grp@oracle.com




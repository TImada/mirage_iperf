# mirage_iperf
iperf like tool on MirageOS

## Description
This program is a network performance measurement tool on MirageOS based on the test iperf implementation included in mirage-tcpip (https://github.com/mirage/mirage-tcpip). You can measure the TCP throughput between two different MirageOS VMs by this tool.

## Requirement
MirageOS and hypervisor software(Xen or QEMU/KVM) are required.
Libvirt with virsh(https://libvirt.org/) and jq (https://stedolan.github.io/jq/) are also required if you conduct an automated measurement framework provided by `iperf_run.sh`

## Usage
### Usual
1. Compile a server side program in `iperf_server` and a client side program in `iperf_client`.
2. Launch the server side at first, then the client side.

### Automated measurement
1. Modify domain xml files in ./template/ so that they can use a network bridge on your environment. The default bridge is `vmbr0`.  
2. Modify parameters in `iperf_run.sh` so that it can be used on your environment.  
3. Execute `./iperf_run xen /path/to/dir` if you want to launch the client and server side programs at `/path/to/dir` on Xen-based physical servers. "virtio" can be used for QEMU/KVM-based physical servers.


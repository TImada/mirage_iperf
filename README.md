# mirage_iperf
iperf tool on MirageOS

## Description
This program is a network performance measurement tool on MirageOS based on the test iperf implementation included in mirage-tcpip (https://github.com/mirage/mirage-tcpip). You can measure the TCP throughput between two different MirageOS VMs by this tool.

## Requirement
- MirageOS
- Hypervisor software(Xen or QEMU/KVM)
- Libvirt with virsh(https://libvirt.org/) and jq (https://stedolan.github.io/jq/)  
(if you conduct an automated measurement framework provided by `iperf_run.sh` or `iperf_hvm_run.sh`)

## Usage
### Step by step
1. Check your target path.  
TCP client in `iperf_client`, TCP server in `iperf_server`  
UDP client in `iperf_udp_client`, UDP server in `iperf_udp_server`
2. Edit the following variables in unikernel.ml of your target client program.
    - `server_ip` (= server IP address)
    - `total_size` (= total data size to be sent)
    - `blen` (= sender buffer size)
3. Configure your target programs. You must assign an IP address for each side in this step.
```
(client side using hvt)
$ mirage configure --ipv4=192.168.122.11/24 -t hvt
(server side using hvt)
$ mirage configure --ipv4=192.168.122.10/24 -t hvt
```
4. Compile your target programs.
5. Launch the server side at first, then the client side.

### Automated measurement
- Xen or QEMU/KVM
  1. Modify domain xml files in ./template/ so that they can use a network bridge on your environment. The default bridge is `vmbr0`.  
  2. Modify parameters in `iperf_run.sh` so that it can be used on your environment.  
  `CLIENTADDR` : A host IP for libvirt where you want to run a client side VM
  `SERVERADDR` : A host IP for libvirt where you want to run a server side VM  
  `USER` : A username you want to use  
  `OCAMLVER` : An OCaml compiler version you want to use
  `BUFSIZE` : Sender buffer size  
  `ITERATIONS` : # of measurements for each sender buffer size
  3. Execute `./iperf_run xen tcp /path/to/dir` if you want to launch the TCP client and server side programs at `/path/to/dir` on Xen-based physical servers.  
  1st argument : `xen` or `virtio`  
  2nd argument : `tcp` or `udp`  
  3rd argument : `/path/to/dir` (where you want to put the server and client kernel files)  
- hvt
  1. Create and configure two tap devices on your hosts and check if they can communicate each other.
  2. Modify parameters in `iperf_hvt_run.sh`. The default tap devices are `tap0` and `tap1` for the server and client respectively.
  3. Execute `./iperf_hvt_run.sh tcp` if you want to launch the TCP client and server side programs.  
  1st argument : `tcp` or `udp`

## Note
- UDP-based programs are partly compatible with the C-based iperf. This is just for testing. (The programs were tested with iperf-2.0.9)  
  - C-based client with MirageOS-based server  
  __Note that you can check only the bytes transferred and bit rate.__ The jitter and packet loss rate fields (= indicated as "Server report:" in the client side output) are invalid as the server side does not measure them.  
  - MirageOS-side client with C-based client  
  No special considerations needed.

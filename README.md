# mirage_iperf

iperf tool on MirageOS

## Description

This program is a network performance measurement tool on MirageOS based on the test iperf implementation included in mirage-tcpip (https://github.com/mirage/mirage-tcpip). You can measure the TCP throughput between two different MirageOS VMs by this tool.

## Requirement

- MirageOS
- Solo5

## Usage

### (1) TAP/Bridge configuration

You need to create a brigde device and two TAP devices attached to it. They can be created easily if you use `set_tap.sh` included in this repository. `set_tap.sh` will create a bridge device and two TAP devices below by default.

```
|-------|     |--------------------|     |-------|
| veth0 |-----|       virbr0       |-----| veth1 |
|-------|     | 192.168.122.254/24 |     |-------|
              |--------------------|
```

Change variable values below in `set_tap.sh` if it can affect the current network configuration on your testbed.

| Variable | Default value | Note |
|:-:|:-:|:-:|
| `BRIP` | 192.168.122.254 | Bridge device IP address |
| `MASK` | 24 | Network mask for the bridge device |
| `BRIF` | virbr0 | Brige device name |
| `TAPIF0` | veth0 | 1st TAP device name |
| `TAPIF1` | veth1 | 2nd TAP device name |


Invoke `set_tap.sh` to configure the network used for this repository. (`set_tap.sh` requires the `sudo` command)

```bash
$ cd /path/to/mirage_iperf
$ ./set_tap.sh
```

### (2) iperf execution

#### 1. Check your target path.

TCP client in `iperf_client`, TCP server in `iperf_server`  
UDP client in `iperf_udp_client`, UDP server in `iperf_udp_server`

#### 2. Configure your target programs. (Using solo5-hvt is assumed)

```
$ mirage configure -t hvt
```

#### 3. Compile your target programs.

```
$ make
```

#### 4. Launch the server side at first, then the client side.

```bash
# TCP performance measurement
## TCP server
$ sudo /path/to/solo5-hvt --mem=64 --net:service=veth0 -- ./dist/iperf_server.hvt --ipv4=192.168.122.10/24

## TCP client
$ sudo /path/to/solo5-hvt --mem=64 --net:service=veth1 -- ./dist/iperf_client.hvt --ipv4=192.168.122.20/24 --dest_ip=192.168.122.10 --total_bytes=1000000000

# UDP performance measurement
## UDP server
$ sudo /path/to/solo5-hvt --mem=64 --net:service=veth0 -- ./dist/iperf_udp_server.hvt --ipv4=192.168.122.10/24

## UDP client
$ sudo /path/to/solo5-hvt --mem=64 --net:service=veth1 -- ./dist/iperf_udp_client.hvt --ipv4=192.168.122.20/24 --dest_ip=192.168.122.10 --total_bytes=100000000
```

## Note

UDP-based programs are partly compatible with the C-based iperf. This is just for testing. (They were tested with iperf-2.0.9)

- C-based client with MirageOS-based server
  - __Note that you can check only the bytes transferred and bit rate.__ The jitter and packet loss rate fields (= indicated as "Server report:" in the client side output) are invalid as the server side does not measure them.
- MirageOS-side client with C-based server
  - No special considerations needed.

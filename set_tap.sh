#! /bin/sh

################################################################################
# This script creates a bridge device and two TAP devices below by default.    # 
#                                                                              # 
# |-------|     |--------------------|     |-------|                           #
# | veth0 |-----|       virbr0       |-----| veth1 |                           #
# |-------|     | 192.168.122.254/24 |     |-------|                           #
#               |--------------------|                                         #
#                                                                              # 
################################################################################

BRIP=192.168.122.254
MASK=24
BRIF=virbr0
TAPIF0=veth0
TAPIF1=veth1

# Create a bridge
sudo ip link add name $BRIF type bridge

# Create and enable taps
sudo ip tuntap add dev $TAPIF0 mode tap
sudo ip link set dev $TAPIF0 up
sudo ip link set dev $TAPIF0 master $BRIF
sudo ip tuntap add dev $TAPIF1 mode tap
sudo ip link set dev $TAPIF1 up
sudo ip link set dev $TAPIF1 master $BRIF

# Enable the bridge
sudo ip link set dev $BRIF up
echo 1 | sudo tee /proc/sys/net/ipv4/conf/$BRIF/proxy_arp > /dev/null
echo 1 | sudo tee /proc/sys/net/ipv4/conf/$BRIF/proxy_arp_pvlan > /dev/null
sudo ip addr add $BRIP/$MASK dev $BRIF


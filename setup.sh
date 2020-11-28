#!/bin/bash

. sources/colors
. install/

_pre-install() {

	if [[ $EUID -ne 0 ]]; then
	echo_warn "This setup requires user to be root. su or sudo -s and run again ..."
	exit 1
	fi
}

_basic-setup() {

	echo_query "IP Address:"
	read ip
	echo_progress_start "IP Address is: $ip"

	cp /etc/network/interfaces /etc/network/interfaces.backup
	rm /etc/network/interfaces
	cat > /etc/network/interfaces << EOF

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug ens192
iface ens192 inet static
address $ip
netmask 255.255.255.0
gateway 192.168.1.1
nameserver 192.168.1.10, 192.168.1.11
EOF

	echo_success "IP Address $ip has been setup properly..."

}

_pre-install
_basic-setup

#!/bin/bash

. sources/colors

_pre-install() {

	if [[ $EUID -ne 0 ]]; then
	echo_warn "This setup requires user to be root. su or sudo -s and run again ..."
	exit 1
	fi
}

_basic-setup() {

	echo_query "User:"
	read user
	echo_query "Password:"
	read pass
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

_general-install() {

	echo_progress_start "Installing basic programs"
	apt-get -q -y install ncdu htop dnsutils net-tools git curl figlet lolcat samba > /dev/null
	echo_success "All general programs have been installed..."
}

_ssh() {

        if [[ ! -z $(which ssh) ]]; then
                echo_progress_start "Setting up SSH..."
                echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
        else
                echo_warn "SSH is not installed..."
        fi

        echo_progress_start "Restarting SSH Service..."
        service ssh restart
        echo_success "SSH is properly configured"
}

_samba() {

	echo_progress_start "Installing Samba..."

	cat > /etc/samba/smb.conf << EOF

[global]
   workgroup = WORKGROUP

   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user

[homes]
   comment = Home Directories
   browseable = no
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S

EOF

	echo -ne "$pass\n$pass\n" | smbpasswd -a $user > /dev/null

	echo_success "Samba successfully installed..."

}

_motd() {

	echo_progress_start "Installing the MOTD script"
	cp scripts/update-motd.d/* /etc/update-motd.d/
	chmod +x /etc/update-motd.d/*

	sed -i 's/motd=\/run\/motd.dynamic/motd=\/run\/motd.dynamic.new/' /etc/pam.d/sshd

	echo_success "MOTD has been installed, you can edit /etc/update-motd.d/40-services..."

}


_pre-install
_basic-setup
_general-install
_ssh
_samba
_motd

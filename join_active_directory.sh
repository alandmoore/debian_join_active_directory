#!/bin/bash

# Feel free to replace with your favorite PM frontend
INSTALL_CMD="aptitude install"


# This script should join Debian Jessie (8) to an Active Directory domain.
echo "Please authenticate with your sudo password"
sudo -v

if ! $(sudo which realmd 2>/dev/null); then
    sudo $INSTALL_CMD realmd adcli sssd
fi

if ! $(sudo which ntpd 2>/dev/null); then
    sudo $INSTALL_CMD install ntp
fi

sudo mkdir -p /var/lib/samba/private

echo "Please enter the domain you wish to join: "
read DOMAIN

echo "Please enter a domain admin login to use: "
read ADMIN

sudo realm join --user=$ADMIN $DOMAIN

if [ $? -ne 0 ]; then
    echo "AD join failed.  Please run 'journalctl -xn' to determine why."
    exit 1
fi

# This step was necessary for some users, since this file isn't always created.
sudo touch /etc/sssd/sssd.conf

sudo systemctl enable sssd
sudo systemctl start sssd

echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" | sudo tee -a /etc/pam.d/common-session

# configure sudo
sudo $INSTALL_CMD libsss-sudo

echo "%domain\ admins@$DOMAIN ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/domain_admins

echo "The computer is joined to the domain.  Please reboot, ensure that you are connected to the network, and you should be able to login with domain credentials."

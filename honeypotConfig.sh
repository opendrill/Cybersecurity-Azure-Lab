#!/bin/bash
#cloud-init runs as root.

set -euo pipefail

#Install dependancies.
apt update && apt upgrade
apt install -y  python3-pip python3-venv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind

#Ubuntu 26.04 LTS uses UFW by default, but I want nftables.
systemctl stop ufw.service
systemctl disable ufw.service
apt remove -y ufw

#Configure nftables to redirect port 22 ssh connections to Cowrie. Excluding bastion connections.
systemctl start nftables.service
systemctl enable nftables.service
nft add table ip cowrie
nft add chain ip cowrie nat '{ type nat hook prerouting priority dstnat; }'
nft add rule ip nat prerouting tcp dport 22 ip saddr != 10.0.0.64/26 redirect to 2222 #If the connecting ipv4 address is not in the bastion subnet range then redirect port 22 connections to port 2222 (Cowrie)

#Create cowrie user.
adduser --disabled-password cowrie
usermod -aG sudo cowrie
su - cowrie

#Set up and start cowrie.
mkdir /home/cowrie/honeypot
cd /home/cowrie/honeypot
python3 -m venv cowrie-env
source cowrie-env/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install cowrie
cowrie init
cowrie start

mkdir honeypot
cd honeypot
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install cowrie
cowrie init
# Edit etc/cowrie.cfg as needed
cowrie start

#Automatically start cowrie with systemd in case the vm restarts.
systemctl daemon-reload
systemctl start cowrie.service
systemctl enable cowrie.service

#Install Azure Sentinel agent. Must do later, haven't set up monitoring rg yet.


#var/log/cowrie, var/lib/cowrie, var/lib/cowrie/downloads, var/lib/cowrie/tty, var/run
#var/log/auth.log
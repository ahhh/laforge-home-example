#!/bin/bash
export DEBCONF_NONINTERACTIVE_SEEN=true
export DEBIAN_FRONTEND=noninteractive

# Google DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Upgrade lyfe
apt -qy update > /dev/null
apt -qy upgrade > /dev/null

# Basic template features
echo "world" >> /tmp/hello
echo "{{ $.Host.Hostname }}-{{ $.Environment.Prefix }}{{ $.PodID }}" | tee -a /tmp/whoami

# Install a webserver
apt -yq install apache2

#!/usr/bin/env bash
#
# Install Puppet from the offical APT repo

set -x  # Print commands
set -e  # Fail on error

# Exit immediately if the right version of Puppet is already installed
PUPPET_VERSION=5.4.0
if dpkg -l | grep "puppet.*$PUPPET_VERSION" > /dev/null
then
    echo "Puppet v$PUPPET_VERSION already installed"
    exit 0
fi

function waitFor() {
    while sudo fuser "$1" >/dev/null 2>&1; do 
        echo "Waiting for $1..."; 
        sleep .2; 
    done
}

# Installation instructions taken from 
# https://docs.puppetlabs.com/guides/install_puppet/install_debian_ubuntu.html
DEBFILE=puppet-release-bionic.deb
wget https://apt.puppetlabs.com/$DEBFILE
waitFor "/var/lib/dpkg/lock-frontend" && sudo dpkg -i $DEBFILE
waitFor "/var/lib/apt/lists/lock" && sudo apt-get update
waitFor "/var/lib/dpkg/lock-frontend" && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y puppet
rm $DEBFILE


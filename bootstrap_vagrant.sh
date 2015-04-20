#!/bin/sh
set -xe
type git || yum -y install git || (apt-get update; apt-get -y install git)
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr
/vagrant/install.sh /usr

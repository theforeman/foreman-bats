#!/bin/sh
set -xe
type git || yum -y install git || (apt-get update; apt-get -y install git)
if grep -q ^8 /etc/debian_version ; then
  # Problem with mirror.rackspace.com
  echo "deb http://ftp.debian.org/debian/ jessie main contrib non-free\ndeb http://security.debian.org/ jessie/updates main contrib non-free" >/etc/apt/sources.list
  apt-get update
fi
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr
/vagrant/install.sh /usr

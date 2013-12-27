#!/bin/sh
set -x
type git || yum -y install git || apt-get -y install git
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local
git clone https://github.com/lzap/foreman-bats.git && foreman-bats/install.sh /usr/local

#!/bin/sh
BATS_REPOOWNER=${BATS_REPOOWNER:-theforeman}
BATS_BRANCH=${BATS_BRANCH:-master}
set -x
#yum repolist
type git || yum -y install git || apt-get -y install git
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local
git clone https://github.com/$BATS_REPOOWNER/foreman-bats.git -b $BATS_BRANCH && foreman-bats/install.sh /usr/local

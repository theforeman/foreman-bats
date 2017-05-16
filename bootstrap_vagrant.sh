#!/bin/sh
set -xe

# Wait for boot to complete, in case cloud-init, rc.local etc. are using the
# package database
if type systemctl; then
  while true; do
    state=$(systemctl is-system-running || true)
    if [ x$state = xrunning ]; then
      break
    elif [ x$state = xdegraded ]; then
      (
        echo "System state is degraded, failed services:"
        systemctl --failed --no-pager
        echo "continuing anyway..."
      ) >&2
      break
    else
      sleep 1
    fi
  done
fi

type git || yum -y install git || (apt-get update; apt-get -y install git)
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr
/vagrant/install.sh /usr

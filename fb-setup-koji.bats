#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

@test "install git and createrepo" {
  yum -y install git createrepo yum-plugin-priorities
}

@test "install lzap tools" {
  git clone https://github.com/lzap/bin-public.git /root/bin
  export PATH=$PATH:/root/bin
}

@test "download koji build" {
  export KOJIDIR=/tmp/koji-repo
  mkdir -p $KOJIDIR
  koji-download "$KOJI_BUILD"
}

@test "createrepo koji build" {
  createrepo /tmp/koji-repo
}

@test "setup local koji repo" {
    cat >/etc/yum.repos.d/local-koji.repo <<'EOF'
[local-koji]
name=Local Koji Repo
baseurl=file:///tmp/koji-repo
enabled=1
priority=50
gpgcheck=0
EOF
}

@test "yum makecache" {
  yum makecache
}

# foreman-bats

BATS installation and cli end-to-end testing scripts for Foreman project

    $ git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local
    $ git clone https://github.com/theforeman/foreman-bats.git && foreman-bats/install.sh /usr/local
    $ fb-install-foreman.bats
     ✓ enable epel
     ✓ download and install release package
     ✓ install installer
     ✓ run the installer
     ✓ wait a 10 seconds
     ✓ check web app is up
     ✓ wake up puppet agent
     ✓ install all compute resources
     ✓ restart httpd server
     ✓ collect important logs

    10 tests, 0 failures

There is also a helper script that automates git installation and installation
of BATS and Foreman BATS:

    curl -Ls https://raw.github.com/theforeman/foreman-bats/master/bootstrap.sh | bash /dev/stdin

## Available scripts

### Foreman installation test (fb-install-foreman.bats)

This test will perform default Foreman installation.

The following environment variables can be specified:

* `FOREMAN_REPO`: directory name under yum.tf.org (e.g. /releases/1.3, nightly),
  or component under deb.tf.org (1.3, nightly) to use as Foreman repo
* `FOREMAN_CUSTOM_URL`: custom repo URL to configure, overrides use of
  `FOREMAN_REPO` for the main Foreman URL
* `MODULE_PATH`: override the location of modules used for installation
* `FOREMAN_DB_TYPE`: database type (value can be postgresql (default)/mysql/sqlite)
* `FOREMAN_USE_ORGANIZATIONS`: whether to use organizations or not (value can be true/false)
* `FOREMAN_USE_LOCATIONS`: whether to use locations or not (value can be true/false).
* `FOREMAN_ADMIN_PASSWORD`: initial admin password (defaults to "admin")
* `FOREMAN_EXPECTED_VERSION`: version number of Foreman and components that is expected to be
  installed

### Foreman Puppet integration test (fb-puppet-tests.bats)

This tests that the Puppet agent and master are functioning and that Foreman can
import and assign classes for the agent to apply.

### Puppet installation (fb-install-puppet.bats)

It configures different Puppet distributions than the OS default and should be
run before installing Foreman.  The following environment variables can be
specified:

* `PUPPET_REPO`: one of the following repo keywords:
    * `backports` - packages from [Debian Backports](https://backports.debian.org/)
    * `nightly` - packages from [nightlies.puppetlabs.com](http://nightlies.puppetlabs.com/)
    * `pc1` - packages from [Puppet Collection 1](https://docs.puppet.com/puppet/latest/puppet_collections.html)
    * `stable` - packages from [Puppet 3.x repositories](https://docs.puppet.com/puppet/3.8/puppet_repositories.html) (default)

### Foreman Hammer CLI smoke test (fb-hammer-tests.bats)

Checkouts and executes hammer integration tests. They will create new
(randomly named) organization and populate various fields, then delete
everything.

The following environment variables can be specified:

* `HAMMER_TEST_PATH`: /usr/share/hammer-tests by default, if exists will be
  used instead of the git checkout
* `HAMMER_TEST_REPO`: path to the hammer tests' git repo, default is https://github.com/theforeman/hammer-tests.git
* `HAMMER_TEST_BRANCH`: branch to checkout, default is master

### oVirt installation with integration tests (fb-install-ovirt.bats)

This test installs oVirt's All-In-One setup and
perform basic rbovirt integration test. It requires hardware with
virtualization support, works fine in nested KVM as well. It accepts the
following parameters:

* `OVIRT_RELEASE`: version to install specified as simple number (33, 34, 35)

### Libvirt compute resource installation (fb-setup-libvirt.bats)

It is possible to configure Compute Resource within Foreman against libvirt
running on localhost. The `fb-setup-libvirt.bats` can be used to install
necessary bits (libvirt), configure them and associate required resources in
Foreman. This script must be executed after `fb-install-foreman.bats`.

To use nested KVM you only need to do this on the *host* machine:

    echo 'options kvm-intel nested=1' | sudo tee /etc/modprobe.d/kvm-intel.conf

You can either restart your host machine, or `modprobe kvm-intel` and
restarting libvirtd daemon.

### umask configuration (fb-setup-umask.bats)

This changes the system-wide umask for new shells in order to run other tests
under stricter or different defaults.

* `FOREMAN_UMASK`: umask value, e.g. `077`

## Vagrant support

A Vagrantfile is supplied with multi-OS support.  This will transfer
foreman-bats to the VM and tests can then be executed via `vagrant ssh`:

    vagrant up
    vagrant ssh -c 'sudo /vagrant/fb-install-foreman.bats'
       # or...
    vagrant up wheezy
    vagrant ssh wheezy -c 'sudo /vagrant/fb-install-foreman.bats'

It is also possible to test a different set of modules on all supported
platforms:

    git clone --recursive https://github.com/theforeman/foreman-installer local
    vagrant up
    for vm in precise squeeze wheezy f19 el6 ; do
        vagrant ssh $vm -c 'sudo MODULE_PATH=/vagrant/local/modules /vagrant/fb-install-foreman.bats'
    done

The size of the VM created by Vagrant depends on the value of the `PUPPET_REPO`
environment variable, so export it when running `vagrant up`.

## Support for virt-builder/virt-install

This git repo comes with a virt-spawn wrapper script around virt-builder and
virt-install tools. It creates disk images via virt-builder seeding bats
script for the first boot (`--script` option, by default it deploys
fb-install-foreman.bats script). Then it spawns the image on libvirt via
virt-install.

The tool have many options and it also configures dnsmasq for hostnames. See
the `--help` option to get instructions how to take advantage of that feature.
Few examples:

    virt-spawn -n my-nightly-foreman -f
    virt-spawn -n rc-foreman --script fb-my-script.bats -- "FOREMAN_REPO=rc" "MYVAR=value"
    virt-spawn -n bz981123 -- "KOJI_BUILD=http://mykoji.blah/taskinfo?taskID=97281"

## Koji support

It is possible to execute BATS suite that configures local repository
containing a build specified by URL of a Koji/Brew instance. The repository
has higher priority and therefore builds will be picked up. This is great for
testing installer or any other packages that needs to be installed in early
stage. Example:

    export KOJI_BUILD="http://koji.katello.org/koji/taskinfo?taskID=97092"
    fb-setup-koji.bats
    fb-install-foreman.bats

Just make sure the URL points to a "leaf" task, a page with (S)RPMs and not
parent task.

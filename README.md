foreman-bats
============

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

    curl --silent https://raw.github.com/theforeman/foreman-bats/master/bootstrap.sh | bash /dev/stdin

When using fb-install-foreman.bats, the following environment variables can be
specified:

* FOREMAN_REPO: directory name under yum.tf.org (e.g. /releases/1.3, nightly),
  or component under deb.tf.org (1.3, nightly) to use as Foreman repo
* FOREMAN_CUSTOM_URL: custom repo URL to configure, overrides use of
  FOREMAN_REPO for the main Foreman URL
* MODULE_PATH: override the location of modules used for installation.

Vagrant support
---------------

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

Koji support
------------

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

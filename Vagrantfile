# vim: sw=2:ts=2:et:ft=ruby

boxes = [
  {:name => 'precise',  :libvirt => 'fm-ubuntu1204', :rackspace => /Ubuntu.*12\.04/, :username => 'ubuntu'},
  {:name => 'squeeze',  :libvirt => 'fm-debian6',    :rackspace => /Debian.*6/,      :username => 'debian'},
  {:name => 'wheezy',   :libvirt => 'fm-debian7',    :rackspace => /Debian.*7/,      :username => 'debian'},
  {:name => 'f19',      :libvirt => 'fm-fedora19',   :rackspace => /Fedora.*19/, :pty => true},
  {:name => 'f20',      :libvirt => 'fm-fedora20',   :rackspace => /Fedora.*20/, :pty => true},
  {:name => 'el6',      :libvirt => 'fm-centos64',   :rackspace => /CentOS.*6\.4/, :default => true, :pty => true},
]

if ENV['box']
  boxes << {:name => ENV['box'], :libvirt => ENV['box'], :rackspace => ENV['box'], :username => ENV['box']}
end

Vagrant.configure("2") do |config|
  boxes.each do |box|
    config.vm.define box[:name], primary: box[:default] do |machine|
      machine.vm.box = box[:name]
      machine.vm.hostname = "foreman-#{box[:name]}.example.com"
      machine.vm.provision :shell, :path => 'bootstrap_vagrant.sh'

      machine.vm.provider :libvirt do |p, override|
        override.vm.box = "#{box[:libvirt]}"
        override.vm.box_url = "http://m0dlx.com/files/foreman/boxes/#{box[:libvirt].sub(/^fm-/, '')}.box"
        p.memory = 1024
      end

      machine.vm.provider :rackspace do |p, override|
        override.vm.box = 'dummy'
        p.server_name = machine.vm.hostname
        p.flavor = /1GB/
        p.image = box[:rackspace]
        override.ssh.pty = true if box[:pty]
      end

      # ~/.vagrant.d/Vagrantfile will need
      # config.ssh.private_key_path = "~/.ssh/id_greg"        # private key for keypair below

      config.vm.provider :openstack do |p, override|
        override.vm.box = 'dummy'
        p.server_name   = machine.vm.hostname
        p.flavor        = /m1.tiny/
        p.image         = box[:rackspace] # Might as well use consistent image names
        p.ssh_username  = box[:username]  # login for the VM

        # ~/.vagrant.d/Vagrantfile will need
        # p.username     = "admin"                            # e.g. "#{ENV['OS_USERNAME']}"
        # p.api_key      = "secret"                           # e.g. "#{ENV['OS_PASSWORD']}"
        # p.endpoint     = "http://amethyst:5000/v2.0/tokens" # e.g. "#{ENV['OS_AUTH_URL']}/tokens"
        # p.keypair_name = "Greg"                             # as stored in Nova

        # You may need
        # p.floating_ip = '172.20.10.160' # Must be hardcoded, cannot ask Openstack for an IP
      end

    end
  end
end

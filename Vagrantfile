# vim: sw=2:ts=2:et:ft=ruby

boxes = [
  {:name => 'precise',  :libvirt => 'fm-ubuntu1204', :image_name => /Ubuntu.*12\.04/, :os_user => 'ubuntu'},
  {:name => 'trusty',   :libvirt => 'fm-ubuntu1404', :image_name => /Ubuntu.*14\.04/, :os_user => 'ubuntu'},
  {:name => 'squeeze',  :libvirt => 'fm-debian6',    :image_name => /Debian.*6/,      :os_user => 'debian'},
  {:name => 'wheezy',   :libvirt => 'fm-debian7',    :image_name => /Debian.*7/,      :os_user => 'debian'},
  {:name => 'f19',      :libvirt => 'fm-fedora19',   :image_name => /Fedora.*19/,                    :pty => true},
  {:name => 'f20',      :libvirt => 'fm-fedora20',   :image_name => /Fedora.*20/,                    :pty => true},
  {:name => 'el6',      :libvirt => 'fm-centos64',   :image_name => /CentOS 6\.5/, :default => true, :pty => true},
  {:name => 'el7',      :libvirt => 'fm-centos70',   :image_name => /CentOS 7/,    :default => true, :pty => true},
]

if ENV['box']
  boxes << {:name => ENV['box'], :libvirt => ENV['box'], :image_name => ENV['box'], :os_user => ENV['box']}
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
        p.flavor = /2 GB Performance/
        p.image = box[:image_name]
        override.ssh.pty = true if box[:pty]
      end

      # ~/.vagrant.d/Vagrantfile will need
      # config.ssh.private_key_path = "~/.ssh/id_rsa"          # private key for keypair below

      config.vm.provider :openstack do |p, override|
        override.vm.box = 'dummy'
        p.server_name   = machine.vm.hostname
        p.flavor        = /m1.tiny/
        p.image         = box[:image_name] # Might as well use consistent image names
        p.ssh_username  = box[:os_user]  # login for the VM

        # ~/.vagrant.d/Vagrantfile will need
        # p.username     = "admin"                             # e.g. "#{ENV['OS_USERNAME']}"
        # p.api_key      = "secret"                            # e.g. "#{ENV['OS_PASSWORD']}"
        # p.endpoint     = "http://openstack:5000/v2.0/tokens" # e.g. "#{ENV['OS_AUTH_URL']}/tokens"
        # p.keypair_name = "my_key"                            # as stored in Nova

        # You may need
        # p.floating_ip = '172.20.10.160' # Must be hardcoded, cannot ask Openstack for an IP
      end

    end
  end
end

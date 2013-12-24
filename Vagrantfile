# vim: sw=2:ts=2:et:ft=ruby

Vagrant.configure("2") do |config|
  config.vm.hostname = "foreman-#{ENV['os']}.example.com"

  config.vm.provider :libvirt do |p, override|
    override.vm.box = case ENV['os']
                      when 'precise'
                        'ubuntu-server-12042-x64-kvm-2'
                      when 'squeeze'
                        'debian-607-x64-kvm-3'
                      when 'wheezy'
                        'debian-710-x64-kvm-2'
                      when 'f19'
                        'fedora-19-x64'
                      else
                        'centos-64-x64-kvm-2'
                      end
  end

  config.vm.provider :rackspace do |p, override|
    override.vm.box = 'dummy'
    p.server_name = "foreman-#{ENV['os']}.example.com"
    p.flavor = /1GB/
    p.image  = case ENV['os']
               when 'precise'
                 /Ubuntu.*12\.04/
               when 'squeeze'
                 /Debian.*6/
               when 'wheezy'
                 /Debian.*7/
               when 'f19'
                 /Fedora.*19/
               else
                 /CentOS.*6\.4/
               end
  end

  config.vm.provision :shell, :path => 'bootstrap_vagrant.sh'
end

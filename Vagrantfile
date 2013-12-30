# vim: sw=2:ts=2:et:ft=ruby

Vagrant.configure("2") do |config|
  config.vm.hostname = "foreman-#{ENV['os'] || 'el6'}.example.com"
  config.vm.box = ENV['box']

  config.vm.provider :libvirt do |p, override|
    override.vm.box = ENV['box'] || case ENV['os']
                      when 'precise'
                        'ubuntu1204'
                      when 'squeeze'
                        'debian6'
                      when 'wheezy'
                        'debian7'
                      when 'f19'
                        'fedora19'
                      else
                        'centos64'
                      end
    override.vm.box_url = "http://m0dlx.com/files/foreman/boxes/#{override.vm.box}.box"
    p.memory = 1024
  end

  config.vm.provider :rackspace do |p, override|
    override.vm.box = 'dummy'
    p.server_name = "foreman-#{ENV['os'] || 'el6'}.example.com"
    p.flavor = /1GB/
    p.image  = ENV['box'] || case ENV['os']
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

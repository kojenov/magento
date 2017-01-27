# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
	config.vm.box = "ubuntu/trusty64"
	config.vm.box_check_update = true

	config.vm.network "forwarded_port", guest: 8191, host: 8191

   config.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "Magento 1.9.1"
   end

  config.vm.provision :shell, path: "bootstrap.sh"
end

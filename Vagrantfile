# File copied from https://github.com/Anomen/vagrant-selenium
# Thanks Anomen for the great work

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = 'printhub.com'
  config.vm.box = 'ubuntu/trusty64'
  config.vm.box_url = 'https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box'

  config.vm.network :forwarded_port, guest: 4444, host: 4444
  config.vm.network :forwarded_port, guest: 80,   host: 8881
  # config.vm.network :private_network, ip: '192.168.33.10'
  config.vm.network :public_network
  # config.vm.provision 'shell', path: 'vagrant_script.sh'

  config.vm.provider :virtualbox do |vb|
    vb.memory = 1024
    vb.cpus = 1
    vb.gui = false
  end
end

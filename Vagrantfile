IMAGE_NAME = "bento/ubuntu-24.04"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.define "ubuntu" do |ubuntu|
    ubuntu.vm.box = IMAGE_NAME
    ubuntu.vm.network "forwarded_port", guest: 22, host: 2207, host_ip: "127.0.0.1"
    ubuntu.vm.network "forwarded_port", guest: 80, host: 8007, host_ip: "127.0.0.1"
    ubuntu.vm.hostname = "ubuntu"
  end

  config.vm.provision "file",
    source: "id_ed25519.pub",
    destination: "/home/vagrant/.ssh/me.pub"

  config.vm.provision "shell", inline: <<-SHELL
    cat /home/vagrant/.ssh/me.pub >> /home/vagrant/.ssh/authorized_keys
  SHELL

    config.vm.provision "shell", path: "install_zabbix.sh"

  config.vm.provision "file",
    source: "zabbix.conf.php",
    destination: "/tmp/zabbix.conf.php"

  config.vm.provision "shell", inline: <<-SHELL
    sudo mv /tmp/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
    sudo chown www-data:www-data /etc/zabbix/web/zabbix.conf.php
    sudo chmod 640 /etc/zabbix/web/zabbix.conf.php
  SHELL

end

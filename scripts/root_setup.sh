. /vagrant/scripts/config.sh
sh /vagrant/scripts/prepare_disks.sh
sh /vagrant/scripts/install_os_packages.sh
sh /vagrant/scripts/configure_docker.sh
sh /vagrant/scripts/install_kvm.sh

cp /vagrant/scripts/*yml  /root/.kcli
cp /vagrant/scripts/*tf  /root/projects/terraform
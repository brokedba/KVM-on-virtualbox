echo "******************************************************************************"    
echo "Install tmate (collaboration tool) " `date`                                                
echo "******************************************************************************" 

curl -L https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz | tar Jxvf - ; mv tmate*/tmate /usr/bin
yum -q -y install jq
echo "******************************************************************************"    
echo "Install KMV and Kcli" `date`                                                
echo "******************************************************************************"    

yum install -q  -y qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client virt-install virt-viewer virt-top libguestfs-tools-c fuse
/usr/libexec/qemu-kvm --version
systemctl enable --now libvirtd
systemctl status libvirtd |grep Active
mkdir /u01/guest_images
sudo setfacl -m u:$(id -un):rwx /u01/guest_images
pip2 uninstall -y urllib3
yum reinstall -q  -y python-requests
modprobe fuse
echo "fuse" > /etc/modules-load.d/fuse.conf
yum install -q  -y http://mirror.centos.org/centos/7/os/x86_64/Packages/OVMF-20180508-6.gitee3198e672e2.el7.noarch.rpm  #UEFI firmware
virt-host-validate
virsh pool-define-as default dir - - - - "/u01/guest_images"
virsh pool-build default
virsh pool-start default 
virsh pool-autostart default
echo
echo +++++ "Install Kcli" `date` +++++++ 
echo
curl https://raw.githubusercontent.com/karmab/kcli/master/install.sh | sh 
#mv  /root/.kcli/profiles.yml  /root/.kcli/profiles.yml.old
alias kcli='docker run --net host -i --rm --security-opt label=disable -v /root/.kcli:/root/.kcli -v /root/.ssh:/root/.ssh -v /u01/guest_images:/u01/guest_images -v /var/run/libvirt:/var/run/libvirt -v $PWD:/workdir quay.io/karmab/kcli'
echo create kcli configuration
kcli create host kvm -H 127.0.0.1 local
sed -i '4 i \ \ virttype: qemu' /root/.kcli/config.yml
echo " adapt kcli alias with the default pool path /u02/guest_image "
cp /root/.bashrc /root/bashrc.old
sed -i '13d' /root/.bashrc
echo "alias kcli='docker run --net host -it --rm --security-opt label=disable -v /root/.kcli:/root/.kcli -v /root/.ssh:/root/.ssh -v /u01/guest_images:/u01/guest_images -v /var/run/libvirt:/var/run/libvirt -v $PWD:/workdir quay.io/karmab/kcli'" >> /root/.bashrc
source /root/.bashrc
cp /vagrant/scripts/profiles.yml  /root/.kcli/
echo "******************************************************************************"
echo "Install terraform." `date`
echo "******************************************************************************"
<<OLDINSTALL
curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform_0.12.24_linux_amd64.zip -d /usr/bin/
OLDINSTALL
yum install -q -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum install -q -y terraform
terraform -version 
cd /root/
terraform init
cd /root/.terraform.d
mkdir plugins
echo
echo " import terraform libvirt provider for CentOS 7 / Fedora "
echo
wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.2/terraform-provider-libvirt-0.6.2+git.1585292411.8cbe9ad0.Fedora_28.x86_64.tar.gz
tar xvf terraform-provider-libvirt-0.6.2+git.1585292411.8cbe9ad0.Fedora_28.x86_64.tar.gz
mkdir -p /root/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64

mv terraform-provider-libvirt /root/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
#mv terraform-provider-libvirt /root/.terraform.d/plugins/
echo
echo " Using Terraform KVM Provider"
echo
mkdir -p /root/projects/terraform
cp /vagrant/scripts/kvm-compute.tf /root/projects/terraform/ 
cp /vagrant/scripts/cloud_init.cfg /root/projects/terraform/ 
echo " import terraformer providers for CentOS 7 / Fedora "
echo
export PROVIDER={all,google,aws,kubernetes,azure}
curl -LO https://github.com/GoogleCloudPlatform/terraformer/releases/download/$(curl -s https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest | grep tag_name | cut -d '"' -f 4)/terraformer-${PROVIDER}-linux-amd64
chmod +x terraformer-${PROVIDER}-linux-amd64
sudo mv terraformer-${PROVIDER}-linux-amd64 /usr/local/bin/terraformer


echo "******************************************************************************"
echo "Install Packer and vault." `date`
echo "******************************************************************************"
  
 sudo yum -q -y install packer

packer  -v
packer -autocomplete-install


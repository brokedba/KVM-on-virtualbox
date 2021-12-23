provider "libvirt" {
 uri = "qemu:///system"
}

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}


# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-disk" {
 name   = "ubuntu-qcow2"
 pool   = "default"
 source = "https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
 format = "qcow2"
}

#resource "libvirt_cloudinit_disk" "commoninit" {
# name           = "commoninit.iso"
# pool           = "default" #CHANGEME
# user_data      = data.template_file.user_data.rendered
# network_config = data.template_file.network_config.rendered
#}

#data "template_file" "user_data" {
# template = file("${path.module}/cloud_init.cfg")
#}

#data "template_file" "network_config" {
# template = file("${path.module}/network_config.cfg")
#}

# Create the machine
resource "libvirt_domain" "ubuntu-vm" {
 name   = "ubuntu-vm"
 memory = "512"
 vcpu   = 1

 #cloudinit = libvirt_cloudinit_disk.commoninit.id

 network_interface {
   network_name = "default"
 }

 # IMPORTANT
 # Ubuntu can hang is a isa-serial is not present at boot time.
 # If you find your CPU 100% and never is available this is why
 console {
   type        = "pty"
   target_port = "0"
   target_type = "serial"
 }

 console {
   type        = "pty"
   target_type = "virtio"
   target_port = "1"
 }

 disk {
   volume_id = libvirt_volume.ubuntu-disk.id
 }
 graphics {
   type        = "spice"
   listen_type = "address"
   autoport    = "true"
 }
}  

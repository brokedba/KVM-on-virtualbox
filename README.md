# KVM-on-virtualbox
KVM lab inside a virtualbox vm (Nested virtualization) using vagrant.
Please check the blog for more details and demo.
 http://www.brokedba.com/2021/12/kvm-lab-inside-virtualbox-vm-nested.html
 
 ![image](https://user-images.githubusercontent.com/29458929/185956857-9d6d2668-e573-4659-b5ca-04117080f576.png)


**Clone the repo**
```
C:\Users\brokedba> git clone https://github.com/brokedba/KVM-on-virtualbox.git
C:\Users\brokedba> cd KVM-on-virtualbox
```

**Start the vm (make sure you have 2Cores and 4GB RAM to spare before the launch)**
```
C:\Users\brokedba> vagrant up
```


KVM nested HOST OS:OEL7

# CREATE A VM INSIDE A NESTED VIRTUAL MACHINE
I will be using KCLI in my example where I will

Create a default storage pool and configure it (already done in my vagrant vm)
```
# kcli create pool -p /u01/guest_images default
# kcli list pool
+--------------+-------------------------+
| Pool         |        Path             |
+--------------+-------------------------+
| default      | /u01/guest_images       |
+--------------+-------------------------+
```
Since kcli uses docker we will need to update the kcli alias according to the pool path      
```
# alias kcli='docker run --net host -it --rm --security-opt label=disable -v /root/.kcli:/root/.kcli -v /root/.ssh:/root/.ssh -v /u01/guest_images:/u01/guest_images -v /var/run/libvirt:/var/run/libvirt -v $PWD:/workdir quay.io/karmab/kcli'
```
Create a default network (already done in my vagrant vm)
```
# kcli create network  -c 192.168.122.0/24 default
# kcli list network
+---------+--------+------------------+------+---------+------+
| Network |  Type  |       Cidr       | Dhcp |  Domain | Mode |
+---------+--------+------------------+------+---------+------+
| default | routed | 192.168.122.0/24 | True | default | nat  |
+---------+--------+------------------+------+---------+------+
```

KCLI makes it very easy to download an image from the cloud repository as shown in below example

 Download ubuntu 1803 from ubuntu cloud image repository
```
# kcli download image ubuntu1804  -p default
Using url https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img...

# kcli list image
+----------------------------------------------------+
| Images                                             |
+----------------------------------------------------+
| /u01/guest_images/bionic-server-cloudimg-amd64.img |
+----------------------------------------------------+
```
You can also use Curl if you have a specific image you want to download
```
# curl –sL image-URL –o /Pool/Path/image.img
```

**Create a vm**
Once the image is in the storage pool you only have to run the kcli create command as below ( see syntax)
```
# kcli create vm ubuntuvm -i ubuntu1804 -P network=default -P virttype=qemu –P  memory=512 -P numcpus=1

Deploying vm ubuntu_vm from profile ubuntu1804...
ubuntu_vm created on local

# kcli list vm
+----------+-------+--------------------------------------+-----+------------+
|    Name  | Status|         Ips  |           Source      |Plan | Profile    |
+----------+-------+--------------+-----------------------+-----+------------+
| ubuntuvm |  up   | 192.168.122.5| bionic-server*md64.img|kvirt| ubuntu1804 |
+----------+-------+--------------+-----------------------+-----+------------+
```
Syntax: 
```
usage : kcli create vm [-h] [-p PROFILE] [--console] [-c COUNT] [-i IMAGE]
                      [--profilefile PROFILEFILE] [-P PARAM]
                      [--paramfile PARAMFILE] [-s] [-w]
                      [VMNAME]

```

**Login to the vm**
The IP address will take some time before it’s assigned but when it’s done, just log in using ssh. kcli creates the vm based on the default ssh key (~/id_rsa).
```
# kcli ssh ubuntuvm
Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 4.15.0-163-generic x86_64)
ubuntu@ubuntuvm:~$ uname -a
Linux ubuntuvm 4.15.0-163-generic #171-Ubuntu SMP Fri Nov 5 11:55:11 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
```
You can also log in using root password, but for this you’ll have to set it during the vm creation via Cloud-init
```
# kcli create vm ubuntuvm -i ubuntu1804 -P network=default -P virttype=qemu \
-P cmds=['echo root:unix1234 | chpasswd']

# virsh console ubuntuvm
Connected to domain ubuntuvm
ubuntuvm login: root
Password:

Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 4.15.0-163-generic x86_64)
root@ubuntuvm:~#
```

Download an Image

# KCLI  tips
kcli configuration is done in ~/.kcli directory, that you need to manually create (done in my vagrant build already). 
It will contain: 
* config.yml generic configuration where you declare clients.
* profiles.yml stores your profiles where you combine things like memory, numcpus and all supported parameters into named profiles to create vms from
For example, you could create the same vm described earlier by storing the vm specs in the profiles.yml
 --- excerpt from ~/.kcli/profiles.yml
```
local_ubuntu1804:
  image: bionic-server-cloudimg-amd64.img
  numcpus: 1
  memory: 512
  nets:
  - default
  pool: default
  cmds:
  - echo root:unix1234 | chpasswd
```
Then call the named profile using the –i argument during the creation of the vm   
```  # kcli create vm ubuntuvm –i local_ubuntu1804 ```

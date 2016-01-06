### INSTALL ###
text
install
url --url=http://repo/repo/os/Linux/CentOS/6/os/x86_64
reboot

### SECURITY ###
selinux --disabled
authconfig --enableshadow --enablemd5
rootpw  --iscrypted $6$5dk70PR3718kwOb5$VILypUGYpORfOx4u4BbXckiGTFvP7u6Afq9nx7qwaqok9meKDCBO3oubT76XtoMalIOcZ4mAyGfgov/nRMrib/

### NETWORK CONF ###
network --onboot yes --device eth0 --bootproto dhcp --noipv6
firewall --service=ssh

### LOCAL ###
lang en_US.UTF-8
keyboard uk
timezone --utc Europe/London

### STORAGE ###

%include /tmp/part-include

volgroup rootvg --pesize=4096 pv.0
logvol swap --name=lv_swap --vgname=rootvg --size=2048
logvol / --fstype=ext4 --name=lv_root --vgname=rootvg --size=2048
logvol /tmp --fstype=ext4 --name=lv_tmp --vgname=rootvg --size=1024
logvol /home --fstype=ext4 --name=lv_home --vgname=rootvg --size=128
logvol /var --fstype=ext4 --name=lv_var --vgname=rootvg --size=1024
logvol /var/log --fstype=ext4 --name=lv_log --vgname=rootvg --size=1024


### PACKAGES ###
%packages
@Base
@Core
@core
@server-policy
openssh-clients
%end

### PRE-INSTALL ###
%pre --logfile /root/install-pre.log
###############################################################################
#!/bin/bash

# Move to other tty so we can display stuff
exec < /dev/tty6 > /dev/tty6
chvt 6
clear

# Find disks and prompt for which one to use.

devs="" ; devid=0

for dev in /sys/block/sd* ; do
  dev=`basename ${dev}`
  devs="${devs} ${dev}"
done

if [[ `echo ${devs}|wc -w` -gt 1 ]] ; then
  printf "More than one disk detected!\n\n"
  printf "%s%6s%12s%33s\n" "DEVICE" "SIZE" "PATH" "MODEL"

  for dev in ${devs} ; do
    size=`fdisk -l /dev/${dev} | awk '/^Disk.*bytes/{print $3,$4} ' | sed -e 's/[:,]//g'`
    path=`ls -l /dev/disk/by-path/ | awk "/${dev}/"'&&!/part/{print $9}'`
    model=`cat /sys/block/${dev}/device/model`
    printf "%s%12s%34s%19s\n" "${dev}" "${size}" "${path}" "${model}"
  done

  while true ; do
    printf "\nPlease specify root disk: " ; read rootdisk
    if ! echo ${devs} | grep -q ${rootdisk} ; then
      printf "Invalid selection! Valid disks are: ${devs}"
      continue
    fi
    printf "You have Chosen: ${rootdisk} is this correct (y/n)? " ; read reply1
    case ${reply1} in
      [Yy]* )
        echo "clearpart --all --drives=/dev/${rootdisk}" >> /tmp/part-include
        echo "part /boot --fstype=ext4 --size=128 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
        echo "part pv.0 --grow --size=1 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
        echo "bootloader --location=mbr --driveorder=/dev/${rootdisk} --append='crashkernel=auth rhgb rhgb quiet'" >> /tmp/part-include
        break ;;
      [Nn]* ) ;;
      * ) echo "Please enter one of ${devs}" ;;
    esac
  done

else
  echo "clearpart --all --drives=/dev/sda" >> /tmp/part-include
  echo "part /boot --fstype=ext4 --size=128 --ondisk=/dev/sda" >> /tmp/part-include
  echo "part pv.0 --grow --size=1 --ondisk=/dev/sda" >> /tmp/part-include
  echo "bootloader --location=mbr --driveorder=/dev/sda --append='crashkernel=auth rhgb rhgb quiet'" >> /tmp/part-include
fi

###############################################################################
# Ask for system hostname

while true ; do
  printf "\nPlease enter the hostname for this machine: " ; read Hostname
  printf "You have Chosen: ${Hostname} is this correct (y/n)? " ; read reply2
  case ${reply2} in
    [Yy]* ) hostname ${Hostname}
      echo "NETWORKING=yes" >> /etc/sysconfig/network
      echo "HOSTNAME=${Hostname}" >> /etc/sysconfig/network
      echo "DHCP_HOSTNAME=${Hostname}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
      break ;;
    [Nn]* ) ;;
    * ) echo "Please enter (y/n)" ;;
  esac
done

# Go back to tty1
exec < /dev/tty1 > /dev/tty1
chvt 1

###############################################################################
%end

### POST-INSTALL ###
%post --logfile /root/install-post.log
(

# Setup SSH key
mkdir /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAxiaxYdjTN+A3Zus5iFtbtkKWBh8iaxNK9Pfhg1L1PevcJmqjhSNnVSVv07BeNtRCq5l6EyULboVFC0hfn2ek+VcbxITOgfa/otzLw3Qyza2/vZRYxUhGOTlLGteDC+V+1m9NXD0IH/VE0XEpabZ97C4VJDXK+Pclkhv4cn/wEP8BADh2W5sg+UwUghS7WqCoSkCycq2iJwWujW/xZ+AslHVFqeKrEKWklh2zkJzs0DW7b1yiLhzH8a3TBAEbGuk6dBUXMnKj9ksdgDnA5QScC8lDXLxBr3p3yU8UVUzbJz0EFoJvsHsYq7k25J269nN0+xZEn7y/u9OduTZADfOqIw== SBT' >> /root/.ssh/authorized_keys
chmod -R 700 /root/.ssh

ChefServer='Chefserver.localdomain'
ChefServerFlat="`echo ${ChefServer}|sed 's/\./_/g'`"

# Install Chef
yum -y --disablerepo=* install http://repo/repo/os/Linux/Software/Chef/chef-12.0.1-1.x86_64.rpm

# Get all the relevent chef config files
mkdir -p /etc/chef
cd /etc/chef/
wget -q http://repo/build/chef/client.rb
wget -q http://repo/build/chef/validation.pem
wget -q http://repo/build/chef/initial.json

# Download the SSL certs
mkdir -p /etc/chef/trusted_certs
openssl s_client -showcerts -connect ${ChefServer}:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > /etc/chef/trusted_certs/${ChefServerFlat}.crt

# Run the inital chef client
chef-client -j /etc/chef/initial.json --environment _default

) 2>&1 >/root/install-post-sh.log
%end
### EOF ###

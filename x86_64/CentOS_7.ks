### INSTALL ###
text
install
url --url=http://repo/os/CentOS/7/os/x86_64
reboot

### SECURITY ###
selinux --enforcing
authconfig --enableshadow --enablemd5
rootpw  --iscrypted $6$5dk70PR3718kwOb5$VILypUGYpORfOx4u4BbXckiGTFvP7u6Afq9nx7qwaqok9meKDCBO3oubT76XtoMalIOcZ4mAyGfgov/nRMrib/

### NETWORK CONF ###
network --onboot yes --bootproto dhcp --noipv6
firewall --service=ssh

%include /tmp/net-include # Generated in set-hostname.sh

### LOCAL ###
lang en_US.UTF-8
keyboard uk
timezone --utc Europe/London

### STORAGE ###

%include /tmp/part-include # Generated in find-disks.sh

volgroup rootvg --pesize=4096 pv.0
logvol swap --name=lv_swap --vgname=rootvg --size=2048
logvol / --fstype=ext4 --name=lv_root --vgname=rootvg --size=4098
logvol /tmp --fstype=ext4 --name=lv_tmp --vgname=rootvg --size=1024
logvol /home --fstype=ext4 --name=lv_home --vgname=rootvg --size=128
logvol /var --fstype=ext4 --name=lv_var --vgname=rootvg --size=1024

### PACKAGES ###
%packages
@Base
@Core
@core
openssh-clients
%end

### PRE-INSTALL ###
%pre --interpreter /bin/bash --log=/mnt/sysimage/root/install-pre.log
###############################################################################

iotty=`tty`
exec < $iotty > $iotty 2> $iotty

# Download and run all the misc scripts
baseurl="http://repo/build/kickstarts/scripts"
mkdir /tmp/build

wget ${baseurl}/set-hostname.sh -O /tmp/build/set-hostname.sh
wget ${baseurl}/find-disks.sh -O /tmp/build/find-disks.sh
chmod +x /tmp/build/*.sh

/tmp/build/set-hostname.sh
/tmp/build/find-disks.sh

###############################################################################
%end

### EOF ###

#! /bin/bash

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

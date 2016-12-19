#! /bin/bash

while true ; do
  printf "\nPlease enter the hostname for this machine: " ; read Hostname
  printf "You have Chosen: ${Hostname} is this correct (y/n)? " ; read reply2

  case ${reply2} in
    [Yy]*)

      if grep -q 'release 6.' /etc/redhat-release ; then
        hostname ${Hostname}
        echo "NETWORKING=yes" >> /etc/sysconfig/network
        echo "HOSTNAME=${Hostname}" >> /etc/sysconfig/network
        echo "DHCP_HOSTNAME=${Hostname}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
      elif grep -q 'release 7.' /etc/redhat-release ; then
        echo "network --hostname=${Hostname}" > /tmp/net-include
      fi
      break
    ;;

    [Nn]* )
    ;;
    * )
      echo "Please enter (y/n)"
    ;;

  esac
done


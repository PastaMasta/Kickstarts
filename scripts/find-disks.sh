#! /bin/bash

# Find disks and prompt for which one to use.


cd /sys/block

devs=""
for dev in `ls -d sd* vd* 2>/dev/null` ; do
  devs="`basename ${dev}` ${devs}"
done

if [[ `echo ${devs}|wc -w` -gt 1 ]] ; then

  printf "\nMore than one disk detected!\n\n"
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

        if [[ -d "/sys/firmware/efi" ]] ; then
	  echo "part /boot/efi --fstype=vfat --size=512 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
	  echo "part /boot --fstype=ext4 --size=512 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
	  echo "part pv.0 --grow --size=1 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
	  echo "bootloader --location=mbr --driveorder=/dev/${rootdisk} --append='crashkernel=auth rhgb rhgb quiet'" >> /tmp/part-include
        else
	  echo "part /boot --fstype=ext4 --size=512 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
	  echo "part pv.0 --grow --size=1 --ondisk=/dev/${rootdisk}" >> /tmp/part-include
	  echo "bootloader --location=mbr --driveorder=/dev/${rootdisk} --append='crashkernel=auth rhgb rhgb quiet'" >> /tmp/part-include
        fi

        break ;;
      [Nn]* ) ;;
      * ) echo "Please enter one of ${devs}" ;;
    esac
  done

else
  echo "clearpart --all --drives=/dev/${devs}" >> /tmp/part-include

  if [[ -d "/sys/firmware/efi" ]] ; then
    echo "part /boot/efi --fstype=vfat --size=512 --ondisk=/dev/${devs}" >> /tmp/part-include
    echo "part /boot --fstype=ext4 --size=512 --ondisk=/dev/${devs}" >> /tmp/part-include
    echo "part pv.0 --grow --size=1 --ondisk=/dev/${devs}" >> /tmp/part-include
    echo "bootloader --location=mbr --driveorder=/dev/${devs}--append='crashkernel=auth rhgb rhgb quiet'" >> /tmp/part-include
  else
    echo "part /boot --fstype=ext4 --size=512 --ondisk=/dev/${devs}" >> /tmp/part-include
    echo "part pv.0 --grow --size=1 --ondisk=/dev/${devs}" >> /tmp/part-include
    echo "bootloader --location=mbr --driveorder=/dev/${devs}--append='crashkernel=auth rhgb rhgb quiet'" >> /tmp/part-include
  fi
fi

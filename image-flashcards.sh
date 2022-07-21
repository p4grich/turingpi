#!/bin/bash

if [[ $@ =~ "-d" ]] || [[ $@ =~ "--debug" ]]; then
  set -x
fi

if [[ $@ =~ "-h" ]] || [[ -z "$@" ]]; then
  echo "argument help:

  exsample: 
  $0 image dev=/dev/sda
  $0 image dev=/dev/sda --copy-cfg

  -d #  debug
  -skip-dd #  skip dd image
  -copy-cfg #  copy configs

  Arg: 1
  image#  write iamge to card
  
  Arg: 2
  dev=/dev/sda #  cf card device

  Arg: 3
  image=os.img #  image file

  Arg: 4
  ip=10.5.94.51 # set fixed address

  Arg: 5
  shortname=master-01 # set hostname 
  "
fi

cmd_args=$@

if [[ ! -f /usr/bin/j2 ]]; then
  echo "Missing /usr/bin/j2, Enter or CTRL-c ro run or quit: apt install j2cli"
  read
  apt install j2cli
  exit 1
fi

if [[ ! -f /usr/bin/pv ]]; then
  echo "Missing /usr/bin/pv, Enter or CTRL-c ro run or quit: apt install pv"
  read
  apt install pv
  exit 1
fi

if [[ $@ =~ "--skip-dd" ]]; then
  skip_dd=true
fi


if [[ -z "$2" ]]; then
  echo "missing device"
  exit 1
else
  DEV=$(echo $2| grep dev| awk -F = '{print $2}')
fi

if [[ -z "$3" ]]; then
  echo "missing image file"
  exit 1
else
  IMAGE=$(echo $3| grep image| awk -F = '{print $2}')
fi

if [[ -z "$4" ]]; then
  echo "missing ip"
  exit 1
else
  ip=$(echo $4| grep ip| awk -F = '{print $2}')
fi

if [[ -z "$5" ]]; then
  echo "missing shortname"
  exit 1
else
  shortname=$(echo $5| grep shortname| awk -F = '{print $2}')
fi

function is_mount() {
  if [[ -d "/media/$USER/HypriotOS" ]]; then
    os_found=hypriot
    mount_path1="/media/$USER/HypriotOS"
    mount_path2="/media/$USER/root"
  fi

  if [[ -d "/media/$USER/boot" ]] && [[ -d "/media/$USER/rootfs" ]]; then
    os_found=rasp
    mount_path1="/media/$USER/boot"
    mount_path2="/media/$USER/rootfs"
  fi

  if [[ -d "/media/$USER/rootfs" ]] || [[ -d "/media/$USER/HypriotOS" ]]; then
    mount_status=yes
  else
    mount_status=no
  fi

  if [[ ${4} == "-f" ]]; then
    write_status=force
  fi

  echo "$os_found $write_status"
}

un_mount(){
  if [[ "$mount_status" == "yes" ]]; then

    $(sudo umount ${mount_path1} )
    $(sudo umount ${mount_path2} )
  fi
}

post(){
  is_mount
  boot="/media/${USER}/HypriotOS"
  root="/media/${USER}/root"
  touch $boot/ssh
  user_data_templated=`echo inventory_hostname_short=$shortname ansible_host=$ip | j2 --format=env roles/bootstrap-core/templates/user-data.j2`
  echo "$user_data_templated" > $boot/user-data
  cp roles/bootstrap-core/files/config.txt $boot/config.txt
  cp roles/bootstrap-core/files/cmdline.txt $boot/cmdline.txt
  un_mount
  exit 0
}

if [[ $@ =~ "--copy-cfg" ]]; then
  post $1
  exit 0
fi

echo $@
is_mount $@

if [[ $@ =~ "image" ]]; then
  if [[ ${os_found} == "rasp" ]] || [[ ${write_status} == "force" ]]; then
    echo "writing image ${IMAGE} to device ${DEV}"
    echo "Are you sure you want to write to the disk at $DEV: CTRL-C to quit"
    read
    if [[ ${skip_dd} == "true" ]]; then
      echo "skipping dd"
    else
      $(/usr/bin/pv ${IMAGE} | sudo dd of=${DEV})
    fi
    un_mount
    echo "ejected fc cards, please reinsert"
    read
    post  $1
    exit 0
  else
    echo "already found $os_found"
    exit 1
  fi
fi

#!/bin/bash

if [[ $@ =~ "-h" ]] || [[ -z "$@" ]]; then
  echo "argument help:

  exsample:   
  $0 master dev=/dev/sda
  $0 master dev=/dev/sda --copy-cfg
  
  -d #  debug
  -skip-dd #  skip dd image
  -copy-cfg #  copy configs
  H#1 #  hoatname post fix number

  Arg: 1
  master #  write master iamge to card
  worker #  write worker iamge to card
  Arg: 2  
  dev=/dev/sda #  cf card device

  Arg: 3  
  image=os.img #  image file 
  "
fi

cmd_args=$@

if [[ ! -f /usr/bin/pv ]]; then
  echo "Missing /usr/bin/pv, Enter or CTRL-c ro run or quit: apt install pv" 
  read
  apt install pv
  exit 1
fi 

if [[ $@ =~ "--skip-dd" ]]; then
  skip_dd=true	
fi

if [[ $@ =~ "H#" ]]; then
  hostpostfix=$(echo $@| awk -F '#' '{print $2}')
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


post(){
  boot="/media/${USER}/HypriotOS"
  root="/media/${USER}/root"
  set -x
  touch $boot/ssh

  if [[ $1 == "master" ]]; then
    echo "master file copy"
    cp user-data.master $boot/user-data
    cp config-master.txt $boot/config.txt
  fi
  if [[ $1 == "worker" ]]; then
    echo "worker file copy"
    cp user-data${hostpostfix}.worker $boot/user-data
    cp config-worker${hostpostfix}.txt $boot/config.txt
  fi
  un_mount
  set +x
}

if [[ $@ =~ "--copy-cfg" ]]; then
  post $1
  exit 0  
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
  set -x	
  if [[ "$mount_status" == "yes" ]]; then
    	  
    $(sudo umount ${mount_path1} )
    $(sudo umount ${mount_path2} )
  fi   
  set +x	
}

echo $@
is_mount $@

if [[ $@ =~ "master" ]]; then
  if [[ ${os_found} == "rasp" ]] || [[ ${write_status} == "force" ]]; then
    echo "writing master image ${IMAGE} to device ${DEV}"
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

if [[ $@ =~ "worker" ]]; then
  if [[ ${os_found} == "rasp" ]] || [[ ${write_status} == "force" ]]; then
    echo "writing worker image ${IMAGE} to device ${DEV}"
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
    echo "already found $os_foud"
    exit 1
  fi 
fi 

#!/bin/bash
if [[ $@ =~ "--debug" ]]; then
  set -ex
fi

if [[ $@ =~ "-h" ]] || [[ -z "$@" ]]; then
st
  echo "argument help:

  example: 
  $0 dev=/dev/sda image=hypriotos-rpi-v1.12.3.img ip=10.5.94.51 shortname=master-01 -F --copy-cfg

  --debug #  debug
  -F #  force overwrite image
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

if [[ $@ =~ "-F" ]]; then
  write_status=force
fi


function is_mount_check() {
  local __argvar=$1
  if [[ -d "/media/$USER/HypriotOS" ]]; then
    os_found=hypriot
    boot_vol="/media/$USER/HypriotOS"
    root_vol="/media/$USER/root"
  fi

  if [[ -d "/media/$USER/boot" ]] && [[ -d "/media/$USER/rootfs" ]]; then
    os_found=rasp
    boot_vol="/media/$USER/boot"
    root_vol="/media/$USER/rootfs"
  fi

  if [[ "$__argvar" == "os_check" ]]; then
     echo $os_found
  fi

  if [[ "$__argvar" == "mount_status_check" ]]; then
    if [[ -d "$root_vol" ]] || [[ -d "$boot_vol" ]]; then
      mount_status=true
    else
      mount_status=false
    fi
  fi
}

function un_mount(){
  $(sudo umount ${root_vol})
  if [[ $? == 0 ]]; then
    echo "umount ${root_vol} OK"
  else
    echo "Error unmounting ${root_vol}"
  fi
 
  $(sudo umount ${boot_vol})
  if [[ $? == 0 ]]; then
    echo "umount ${root_boot} OK"
  else
    echo "Error unmounting ${root_boot}"
  fi
}

is_mount_check mount_status_check
is_mount_check os_check

config_files="config.txt cmdline.txt"
config_file_path="./roles/bootstrap-core/files"
template_files="user-data.j2"
template_file_path="./roles/bootstrap-core/templates"
template_values="inventory_hostname_short=$shortname ansible_host=$ip"
touch_files="ssh"
touch_file_path="$boot_vol"

function post_files(){
    local __cmdvar="$1"
    local __pathvar="$2"
    local __argvars="${@:3}"

    if  [ -d "$__pathvar" ]; then
      echo "${FUNCNAME[0]} path test: PASSED"
    else
      echo "${FUNCNAME[0]} path test: FAILED"
      exit 1
    fi

    if [[ "$__cmdvar" == "touch" ]]; then
      for tf in $__argvars; do
        touch $__pathvar/$tf
        echo "${FUNCNAME[0]} touched file $tf: PASSED"
      done
    fi
    
    if [[ $__cmdvar == "template" ]]; then
      for te in $__argvars; do
        if [[ -f  $__pathvar/$te ]]; then
          echo "${FUNCNAME[0]} file test: PASSWD"
        else
          echo "${FUNCNAME[0]} file test: FAILED"
          exit 1 
        fi 
        save_file=$(basename ${te} .j2)
        user_data_templated=$(echo $template_values | j2 --format=env $__pathvar/$te)
        echo $user_data_templated > $boot_vol/$save_file
      done
      if [[ $? == 0 ]]; then
        echo "${FUNCNAME[0]} jinja2 templating: PASSWD"
      else
        echo "${FUNCNAME[0]} jinja2 templating: FAILED"
        exit 1
      fi
    fi

    if [[ $__cmdvar == "copy" ]]; then
      for c in $__argsvars; do
        cp $__pathvars/$c $boot_vol
      done
      if [[ $? == 0 ]]; then
        echo "${FUNCNAME[0]} copy config files: PASSWD"
      else
        echo "${FUNCNAME[0]} copy config files: FAILED"
        exit 1
      fi
    fi
}

function make_post_file() {
  echo "touch boot files"
  post_files touch $touch_file_path $touch_files

  echo "template files $template_file_path $template_files"
  post_files template $template_file_path $template_files

  echo "copying config files"
  post_files copy $config_file_path $config_files
}



if [[ $@ =~ "--copy-cfg" ]]; then
  if [[ "$mount_status" == "true" ]]; then
    make_post_file
    echo "running unmount"
    un_mount
    exit 0
  else
    echo "--copy-cfg did not find mount, could not copy files: FAILED"
    exit 1
  fi
fi

if [[ $@ =~ "--skip-dd" ]]; then
  echo "setting dd skip"
  skip_dd=true
fi

if [[ ${skip_dd} == "true" ]]; then
    echo "skipping dd"
    post_files
    un_mount
    exit 0
  else
    if [[ ${os_found} == "rasp" ]] || [[ ${write_status} == "force" ]]; then
      echo "writing image ${IMAGE} to device ${DEV}"
      echo "Are you sure you want to write to the disk at $DEV: CTRL-C to quit"
      read
      $(/usr/bin/pv ${IMAGE} | sudo dd of=${DEV})
      if [[ $? == 0 ]]; then
        echo "dd image copy to card: PASSWD"
      else
        echo "dd image copy to card: FAILED"
        exit 1
      fi
    echo "already found $os_found"
      exit 1
    fi

    un_mount
    echo ""
    echo ">>> ejected fc cards, please reinsert <<<"
    read pg
    is_mount

    if [[ "$mount_status" == "true" ]]; then
      make_post_files
      echo "running unmount"
      un_mount
      exit 0
    else
      echo "mount not found"
      echo "Copying config files to fresh image: FAILED"
      exit 1
    fi
    exit 0
fi

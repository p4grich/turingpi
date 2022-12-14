# !/bin/bash
if [[ $@ =~ "--debug" ]]; then
  set -ex
fi

if [[ $@ =~ "-h" ]] || [[ -z "$@" ]]; then
st
  echo "argument help:

  example:
  $0 dev=/dev/sda image=hypriotos-rpi-v1.12.3.img ip=10.5.94.51 shortname=master-01 -F
  $0 dev=/dev/sda image=hypriotos-rpi-v1.12.3.img ip=10.5.94.51 shortname=master-01 -F --copy-cfg

  --debug #  debug
  -F #  force overwrite image to install fresh image
  -skip-dd # force skip dd image
  -copy-cfg #  copy configs only

  Arg: 1
  dev=/dev/sda #  cf card device
  
  image=os.img #  image file

  Arg: 3
  ip=10.5.94.51 # set fixed address

  Arg: 4
  shortname=master-01 # set hostname
  "
fi

if [[ $(id -u) == 0 ]]; then
  echo "Do not run as root or with sudo: FAILED"
  exit 1
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

if [[ -z "$1" ]]; then
  echo "missing device"
  exit 1
else
  DEV=$(echo $1| grep dev| awk -F = '{print $2}')
fi

if [[ -z "$2" ]]; then
  echo "missing image file"
  exit 1
else
  IMAGE=$(echo $2| grep image| awk -F = '{print $2}')
fi

if [[ -z "$3" ]]; then
  echo "missing ip"
  exit 1
else
  ip=$(echo $3| grep ip| awk -F = '{print $2}')
fi

if [[ -z "$4" ]]; then
  echo "missing shortname"
  exit 1
else
  shortname=$(echo $4| grep shortname| awk -F = '{print $2}')
fi

if [[ $@ =~ "-F" ]]; then
  write_status=force
fi


function is_mount_check() {
  local __argvar="$1"
  if [[ -z "$__argvar" ]]; then
      echo $"{FUNCNAME[0]}: $__argvar error"
      exit 99
  fi

  if [ -d "/media/$USER/HypriotOS" ]; then
    os_found="hypriot"
    boot_vol="/media/$USER/HypriotOS"
    root_vol="/media/$USER/root"
  fi

  if [ -d "/media/$USER/boot" ] && [ -d "/media/$USER/rootfs" ]; then
    os_found="rasp"
    boot_vol="/media/$USER/boot"
    root_vol="/media/$USER/rootfs"
  fi

  if [[ "$__argvar" == "mount_status_check" ]]; then
    if [[ -d "$root_vol" ]] || [[ -d "$boot_vol" ]]; then
      mount_status=true
    else
      mount_status=false
      exit 50
    fi
  fi

  if [ "$__argvar" == "os_check" ]; then
     echo $os_found
  else
     os_found=fasle
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
    echo "umount ${boot_vol} OK"
  else
    echo "Error unmounting ${boot_vol}"
  fi
}

is_mount_check "mount_status_check"
is_mount_check "os_check"

config_files="config.txt cmdline.txt"
config_file_path="./roles/bootstrap-core/files"
template_files="user-data.j2"
template_file_path="./roles/bootstrap-core/templates"
template_values="inventory_hostname_short=$shortname ansible_host=$ip"
touch_files="ssh"
touch_file_path="${boot_vol}"


function post_files(){
# pass in command value, then path, then list of filenames
    local __cmdvar="$1"
    local __pathvar="$2"
    local __argvars="${@:3}"
    if [[ -z "$__cmdvar"  ]] || [[ -z "$__cmdvar=" ]] || [[ -z "$__argvars" ]]; then
      echo "${FUNCNAME[0]}: $__cmdvar $__cmdvar= $__argvars error"
      exit 99
    fi
    
    if [ "$mount_status" = fasle ]; then
      echo "flashcard is not mounted"
      exit 50
    fi

    if [ -d "$__pathvar" ]; then
      echo "${FUNCNAME[0]} path test $__pathvar: PASSED"
    else
      echo "${FUNCNAME[0]} path test $__pathvar: FAILED"
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
          echo "${FUNCNAME[0]} file test: PASSED"
        else
          echo "${FUNCNAME[0]} file test: FAILED"
          exit 1 
        fi 
        save_file=$(basename ${te} .j2)
        for e in $template_values; do
          export $e
        done
        user_data_templated=$(echo $template_values | j2 --format=env $__pathvar/$te)
        echo "$user_data_templated" > $boot_vol/$save_file
      done
      if [[ $? == 0 ]]; then
        echo "${FUNCNAME[0]} jinja2 templating: PASSED"
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
        echo "${FUNCNAME[0]} copy config files: PASSED"
      else
        echo "${FUNCNAME[0]} copy config files: FAILED"
        exit 1
      fi
    fi
}


#post_files touch $touch_file_path $touch_files
function make_post_file() {
  post_files "touch" $touch_file_path $touch_files
  post_files "template" $template_file_path $template_files
  post_files "copy" $config_file_path $config_files
}


if [[ $@ =~ "--copy-cfg" ]]; then
  if [ "$mount_status" == true ]; then
    make_post_file
    echo "running unmount"
    un_mount
    exit 0
  else
    echo "Mount not mount"
    echo "--copy-cfg did not find mount, could not copy files: FAILED"
    exit 1
  fi
fi

if [[ $@ =~ "--skip-dd" ]]; then
  echo "setting dd skip"
  skip_dd=true
fi

if [ "$skip_dd" == true ]; then
    echo "skipping dd"
    make_post_file
    un_mount
    exit 0
  else
    if [[ ${os_found} == "rasp" ]] || [[ ${write_status} == "force" ]]; then
      echo "writing image ${IMAGE} to device ${DEV}"
      echo "Are you sure you want to write to the disk at $DEV: CTRL-C to quit"
      read pg
      $(/usr/bin/pv ${IMAGE} | sudo dd of=${DEV})
      if [[ $? == 0 ]]; then
        echo "dd image copy to card: PASSED"
      else
        echo "dd image copy to card: FAILED"
        exit 1
      fi
    else
      echo "already found $os_found"
      exit 1
    fi
    un_mount
    echo ""
    echo "ejected fc cards, please reinsert"
    read pg
    is_mount_check
    if [ "$mount_status" == true ]; then
      make_post_file
      echo "running unmount"
      un_mount
      exit 0
    else
      echo "Mount not mount"
      echo "--copy-cfg did not find mount, could not copy files: FAILED"
      exit 1
    fi
    exit 0
fi

Automaton for TP Cluster.

Bash script to image and setup requierments for auto booting images on TPC
        
    image-flashcards.sh: linux shell script to install HypiorOS on cf cards and tune cloud-init for use with ansible
            
    argument help:
      image-flashcards.sh dev=/dev/sda image=hypriotos-rpi-v1.12.3.img ip=10.5.94.51 shortname=master-01 -F
      image-flashcards.sh dev=/dev/sda image=hypriotos-rpi-v1.12.3.img ip=10.5.94.51 shortname=master-01 -F --copy-cfg

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

cloud-init and boot config file to review prior to boot image.

  - /boot/config.txt   # rpi boot config
  - /boot/cmdline.txta # rpi coot config
  - /boot/user-data    # cloud-init used by hypriot distribution

Ansible inventory:
    as we prepopulated the ip addresses when setting up the images to bypass flacky netwoking.
    please populate the inventory acoorecely accordinglY.
    review addresses found on the network.

      nmap -sn 10.5.94.1/24

    The inventory must have two groups. "node", "master", and "k3s_cluster" to support k3s_cluster deployment correctly.

Ansible setup roles to simplify some prerequsists tasks:

    playbook: tpc_cluster-playbook.yml

      play #1 (all): Deploy TP Cluster for k3s Sturgeon Technologies  TAGS: []
        tasks:
          bootstrap-core : template /boot/user-data                                                         TAGS: [base, cloud-init-cfg]
          bootstrap-core : Copy config.txt to boot                                                          TAGS: [base, boot-config, kernel-tuning]
          bootstrap-core : Copy cmdline.txt to boot                                                         TAGS: [base, boot-cmdline, kernel-tuning]
          bootstrap-core : Set a hostname to:                                                               TAGS: [base, hostname]
          bootstrap-core : Set up multiple authorized keys                                                  TAGS: [base, sshkeys]
          bootstrap-core : Update repositories cache and install "i2c-tools" and "python-smbus" package     TAGS: [base, i2c-tools]
          bootstrap-core : Remove useless packages from the cache                                           TAGS: [apt-autoclean, base, make-release-deploy]
          bootstrap-core : Remove dependencies that are no longer required                                  TAGS: [apt-autoremove, base, make-release-deploy]
          bootstrap-core : Run the equivalent of "apt-get clean" as a separate step                         TAGS: [apt-clean, base, make-release-deploy]
          bootstrap-core : Add IP address of all hosts to all hosts                                         TAGS: [add_hosts, base]


k3s and kubectl quick setup:

Run: k3s_cluster playbook

    cd k3s_cluster
    ansible-playbook -i ../hosts.yml -l k3s_cluster sites.yml


Reading:

  - https://pet2cattle.com/2021/04/k3s-join-nodes

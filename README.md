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


    ansible-playbook -i hosts.yml tpc_cluster-playbook.yml  --limit worker-03   --tags=add-static-address -e "vinet=eth0:1 adhawkip=10.5.94.23" 

MS 1:

    ansible -i hosts.yml all -m ping

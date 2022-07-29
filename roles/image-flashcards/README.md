Role Name
=========

Configure rpi boot configs and cloud-init settings

Requirements
------------
Must have FC mounetd locally

Role Variables
--------------

Example:
cf_mount_boot=/media/moto/HypriotOS
cf_mount_root=/media/moto/root
nic_ip=10.5.94.41
nic_netmask=255.255.255.0
nic_gateway=10.5.94.226
shortname=master-02

Dependencies
------------

Must run locally.

Example Playbook
----------------

  - hosts: localimageflashcards
    connection: local
    roles:
      - {role: image-flashcards, tags: ['image-flashcards']}

License
-------

BSD

Author Information
------------------

Graeme Rich

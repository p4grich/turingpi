Role Name
=========

Bootstrap the core OS for TuringPI Cluster.

Requirements
------------

Define host in ansible inventory.

Unlisted Tags
------------

Never tags, tags not shown by list tasks or list tags.
  - add-static-address
  - enable_avahi

Role Variables
--------------

inventory_hostname_short  # get short hostname from inventory
ansible_user              # username used to ssh to node
vinet                     # add virual interface eth0:1
adhawkip                  # ip adress

Example Playbook
----------------

example

    - hosts: all
      roles:
        - { role: bootstrap-core, tags: ['base'] }

License
-------

BSD

Author Information
------------------

Graeme Rich

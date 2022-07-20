Role Name
=========

Bootstrap the core OS for TuringPI Cluster.

Requirements
------------

Define host in ansible inventory.

Role Variables
--------------

inventory_hostname_short
ansible_user


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

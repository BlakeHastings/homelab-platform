#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.local
timezone: UTC
disable_root: true

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_public_key}
    lock_passwd: true
    shell: /bin/bash

packages:
  - qemu-guest-agent
  - curl
  - git

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent

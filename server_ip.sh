#!/bin/bash
echo --- > /etc/ansible/roles/common/vars/main.yml
echo server_ip: $(ifconfig eth0 |grep inet|head -1| awk '{print $2}') >> /etc/ansible/roles/common/vars/main.yml

echo --- > /etc/ansible/roles/ceph/vars/main.yml
echo server_ip: $(ifconfig eth0 |grep inet|head -1| awk '{print $2}') >> /etc/ansible/roles/ceph/vars/main.yml

echo --- > /etc/ansible/roles/telegraf/vars/main.yml
echo server_ip: $(ifconfig eth0 |grep inet|head -1| awk '{print $2}') >> /etc/ansible/roles/telegraf/vars/main.yml

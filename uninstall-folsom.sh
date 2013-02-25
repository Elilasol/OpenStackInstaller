#!/bin/bash

sudo apt-get -y purge vlan bridge-utils ntp mysql-* python-mysqldb keystone python-keystone python-keystoneclient glance glance-api python-glanceclient glance-common glance-registry python-glance nova-api nova-cert nova-compute nova-compute-kvm nova-doc nova-network nova-objectstore nova-scheduler nova-volume rabbitmq-server novnc nova-novncproxy nova-consoleauth openstack-dashboard memcached apache2* cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient tgt openvswitch-switch
sudo apt-get -y autoremove

rm -rf /etc/glance
rm -rf /var/lib/glance
rm -rf /var/log/glance

rm -rf /etc/keystone
rm -rf /var/lib/keystone
rm -rf /var/log/keystone

rm -rf /etc/mysql
rm -rf /var/lib/mysql
rm -rf /var/log/mysql
rm -rf /var/run/mysqld

rm -rf /etc/cinder
rm -rf /var/lib/cinder
rm -rf /var/log/cinder
rm -rf /var/run/cinder

rm -rf /etc/nova
rm -rf /var/lib/nova
rm -rf /var/log/nova
rm -rf /var/run/nova

rm -rf /etc/horizon*
rm -rf /var/lib/horizon*
rm -rf /var/log/horizon*

rm -rf /etc/apache2
rm -rf /var/log/apache2

userdel libvirt-dnsmasq
groupdel libvirtd

mv ~/.bashrc.orig ~/.bashrc

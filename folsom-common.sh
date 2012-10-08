#!/bin/bash

# Source in configuration file
if [[ -f openstack.conf ]]
then
        . openstack.conf
else
        echo "Configuration file not found. Please create openstack.conf"
        exit 1
fi

configure_package_archive() {
	#echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main" | sudo tee -a /etc/apt/sources.list.d/folsom.list
	sudo rm -f /etc/apt/sources.list.d/folsom.list
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/folsom main" | sudo tee -a /etc/apt/sources.list.d/folsom.list
	sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5EDB1B62EC4926EA
	sudo apt-get update
	sudo apt-get -y dist-upgrade
}

install_base_packages() {
	cat <<PRESEED | debconf-set-selections
mysql-server-5.5 mysql-server-5.5/root_password password $MYSQL_ROOT_PASS
mysql-server-5.5 mysql-server-5.5/root_password_again password $MYSQL_ROOT_PASS
mysql-server-5.5 mysql-server-5.5/start_on_boot boolean true
grub-pc grub-pc/install_devices multiselect /dev/sda
grub-pc grub-pc/install_devices_disks_changed multiselect /dev/sda  
PRESEED
	sudo apt-get -y install vlan bridge-utils ntp mysql-server python-mysqldb
}

configure_mysql() {
	sudo sed -i 's/bind-address.*/bind-address     = $MYSQL_SERVER/' /etc/mysql/my.cnf
	sudo service mysql restart
}

recreate_databases() {
	# MySQL
	# Create database
	for d in nova glance cinder keystone ovs_quantum
	do
		mysql -uroot -p$MYSQL_ROOT_PASS -e "drop database if exists $d;"
		mysql -uroot -p$MYSQL_ROOT_PASS -e "create database $d;"
		mysql -uroot -p$MYSQL_ROOT_PASS -e "grant all privileges on $d.* to $d@\"localhost\" identified by \"$MYSQL_DB_PASS\";"
		mysql -uroot -p$MYSQL_ROOT_PASS -e "grant all privileges on $d.* to $d@\"%\" identified by \"$MYSQL_DB_PASS\";"
	done
}

# Main
configure_package_archive
install_base_packages
configure_mysql
recreate_databases
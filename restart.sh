#!/bin/bash

nova_restart() {
	for P in $(ls /etc/init/nova* | cut -d'/' -f4 | cut -d'.' -f1)
	do
		sudo stop ${P} 
		sudo start ${P}
	done

}

# Main
nova_restart

#!/bin/bash

# Source in configuration file
if [[ -f openstack.conf ]]
then
	. openstack.conf
else
	echo "Configuration file not found. Please create openstack.conf"
	exit 1
fi

QUANTUM_CONF=/etc/quantum/quantum.conf
OVS_QUANTUM_PLUGIN_INI=/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
QUANTUM_L3_AGENT_INI=/etc/quantum/l3_agent.ini
QUANTUM_DHCP_AGENT_INI=/etc/quantum/dhcp_agent.ini
QUANTUM_API_PASTE_INI=/etc/quantum/api-paste.ini

quantum_install() {
	sudo apt-get -y install quantum-server python-cliff quantum-plugin-openvswitch-agent quantum-l3-agent quantum-dhcp-agent python-pyparsing
}

quantum_configure() {
	# quantum.conf
	sudo sed -i 's/^ # auth_strategy.*/auth_strategy = keystone/g' $QUANTUM_CONF
	sudo sed -i 's/^ # fake_rabbit.*/fake_rabbit = False/g' $QUANTUM_CONF
	sudo sed -i 's/^ # fake_rabbit.*/fake_rabbit = False/g' $QUANTUM_CONF

 sudo sed -i "s,^sql_connection.*,sql_connection = mysql://glance:$MYSQL_DB_PASS@$MYSQL_SERVER/glance,g" $GLANCE_REGISTRY_CONF

	# ovs_quantum_plugin.ini
	rm -f $OVS_QUANTUM_PLUGIN_INI
        cat > $OVS_QUANTUM_PLUGIN_INI << EOF
[DATABASE]
sql_connection = mysql://quantum:$MYSQL_DB_PASS@$MYSQL_SERVER:3306/glance
reconnect_interval = 2
[OVS]
tenant_network_type = gre
tunnel_id_ranges = 1:1000
integration_bridge = br-int
tunnel_bridge = br-tun
local_ip = 10.0.0.3
[AGENT]
root_helper = sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf
EOF

	# quantum_l3_agent.ini
        sudo sed -i "s/localhost/$KEYSTONE_ENDPOINT/g" $QUANTUM_L3_AGENT_INI
        sudo sed -i "s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT/g" $QUANTUM_L3_AGENT_INI
        sudo sed -i "s/%SERVICE_USER%/quantum/g" $QUANTUM_L3_AGENT_INI
        sudo sed -i "s/%SERVICE_PASSWORD%/$SERVICE_PASS/g" $QUANTUM_L3_AGENT_INI
        sudo sed -i "s/RegionOne/nova/g" $QUANTUM_L3_AGENT_INI
	sudo sed -i "s/^ # metadata_ip.*/metadata_ip = $NOVA_ENDPOINT/g" $QUANTUM_L3_AGENT_INI
	sudo sed -i "s/^ # use_namespaces*/use_namespaces = False/g" $QUANTUM_L3_AGENT_INI

	# dhcp_agent.ini
	echo "use_namespaces = False" | sudo tee -a $QUANTUM_DHCP_AGENT_INI	

	# api-paste.ini
        sudo sed -i "s/127.0.0.1/$KEYSTONE_ENDPOINT/g" $QUANTUM_API_PASTE_INI
        sudo sed -i "s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT/g" $QUANTUM_API_PASTE_INI
        sudo sed -i "s/%SERVICE_USER%/quantum/g" $QUANTUM_API_PASTE_INI
        sudo sed -i "s/%SERVICE_PASSWORD%/$SERVICE_PASS/g" $QUANTUM_API_PASTE_INI
}

quantum_restart() {
	sudo service quantum-server restart
	sudo service quantum-plugin-openvswitch-agent restart
	sudo service quantum-dhcp-agent restart
	sudo service quantum-l3-agent restart
}

# Main
quantum_install
quantum_configure
quantum_restart
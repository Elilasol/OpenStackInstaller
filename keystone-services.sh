#!/bin/bash

# Assumes ENDPOINT has Compute API, Glance, Keystone and Storage

ENDPOINT=$1
# Initial User and Tenancy, e.g. demo and test
USER=$2
PASSWORD=openstack
TENANCY=$3

if [[ ! $ENDPOINT ]]
then
	echo "Syntax: $(basename $0) KEYSTONE_IP USER TENANCY"
	exit 1
fi

# Using token auth env variables
export SERVICE_ENDPOINT=http://$ENDPOINT:35357/v2.0/
export SERVICE_TOKEN=999888777666


# ENDPOINT URLS
NOVA_PUBLIC_URL="http://$ENDPOINT:8774/v1.1/%tenant_id%"
NOVA_ADMIN_URL=$NOVA_PUBLIC_URL
NOVA_INTERNAL_URL=$NOVA_PUBLIC_URL

GLANCE_PUBLIC_URL="http://$ENDPOINT:9292/v1"
GLANCE_ADMIN_URL=$GLANCE_PUBLIC_URL
GLANCE_INTERNAL_URL=$GLANCE_PUBLIC_URL

KEYSTONE_PUBLIC_URL="http://$ENDPOINT:5000/v2.0"
KEYSTONE_ADMIN_URL="http://$ENDPOINT:35357/v2.0"
KEYSTONE_INTERNAL_URL=$KEYSTONE_PUBLIC_URL

SWIFT_PUBLIC_URL="https://$ENDPOINT:443/v1/AUTH_%tenant_id%"
SWIFT_ADMIN_URL="https://$ENDPOINT:443/v1"
SWIFT_INTERNAL_URL=$SWIFT_PUBLIC_URL



# Create required endpoints
keystone service-create --name nova --type compute --description 'OpenStack Compute Service'
keystone service-create --name swift --type object-store --description 'OpenStack Storage Service'
keystone service-create --name glance --type image --description 'OpenStack Image Service'
keystone service-create --name keystone --type identity --description 'OpenStack Identity Service'



# Create endpoints
for S in NOVA SWIFT GLANCE KEYSTONE
do
	ID=$(keystone service-list | grep -i $S | awk '{print $2}')
	PUBLIC=$(eval echo \$${S}_PUBLIC_URL)
	ADMIN=$(eval echo \$${S}_ADMIN_URL)
	INTERNAL=$(eval echo \$${S}_INTERNAL_URL)
	keystone endpoint-create --region nova --service_id $ID --publicurl $PUBLIC --adminurl $ADMIN --internalurl $INTERNAL
done


# Add Tenants
keystone tenant-create --name=$TENANCY

# Create roles
keystone role-create --name Admin
keystone role-create --name KeystoneServiceAdmin
keystone role-create --name Member

# Create users
TENANT_ID=$(keystone tenant-list | grep $TENANCY | awk '{print $2}')

# Create admin and $USER role
keystone user-create --name admin --tenant_id $TENANT_ID --pass $PASSWORD --email root@localhost --enabled true
keystone user-create --name $USER --tenant_id $TENANT_ID --pass $PASSWORD --email $USER@localhost --enabled true

# Admin User
USER_ID=$(keystone user-list | grep admin | awk '{print $2}')
for R in Admin KeystoneServiceAdmin Member
do
	ROLE_ID=$(keystone role-list | grep "\ $R\ " | awk '{print $2}')
	keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID
done

# $USER
USER_ID=$(keystone user-list | grep $USER | awk '{print $2}')
for R in Admin Member
do
	ROLE_ID=$(keystone role-list | grep "\ $R\ " | awk '{print $2}')
	keystone user-role-add --user $USER_ID --role $ROLE_ID --tenant_id $TENANT_ID
done

# Create the EC2 credentials
keystone ec2-credentials-create --user $USER_ID --tenant_id $TENANT_ID
#! /bin/bash -x

ChefServer='chef.localdomain'
ChefServerFlat="`echo ${ChefServer}|sed 's/\./_/g'`"

# Install Chef
yum -y install http://repo/software/Chef/chef-12.0.1-1.x86_64.rpm

# Get all the relevent chef config files
mkdir -p /etc/chef
cd /etc/chef/
wget -q http://repo/build/chef/client.rb
wget -q http://repo/build/chef/validation.pem
wget -q http://repo/build/chef/initial.json

# Download the SSL certs
mkdir -p /etc/chef/trusted_certs
openssl s_client -showcerts -connect ${ChefServer}:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > /etc/chef/trusted_certs/${ChefServerFlat}.crt

# Run the inital chef client
chef-client -j /etc/chef/initial.json --environment _default

exit $?

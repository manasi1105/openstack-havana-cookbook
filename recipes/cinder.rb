#
# Cookbook Name:: centos-cloud
# Recipe:: cinder
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
    data_bag "ssh_keypairs"    
    action [:create, :add] 
end

# Create database for cinder 
centos_cloud_database "cinder" do
    password node[:creds][:mysql_password]
end

# Install cinder packages
package "openstack-cinder" do
    action :install
end

# Configure service 
centos_cloud_config "/etc/cinder/cinder.conf" do
    command [# Identity service connection
             "DEFAULT auth_strategy keystone",
             "keystone_authtoken auth_host #{node[:ip][:keystone]}",
             "keystone_authtoken admin_tenant_name admin",
             "keystone_authtoken admin_user admin",
             "keystone_authtoken admin_password " <<
             "#{node[:creds][:admin_password]}",
             # Mysql connection
             "DEFAULT sql_connection mysql://cinder:" <<
             "#{node[:creds][:mysql_password]}@localhost/cinder",
             # Message broker
             "DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid",
             "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
	     # Volume group
             "DEFAULT volume_group #{node[:auto][:volume_group]}"]
end

centos_cloud_config "/etc/cinder/api-paste.ini" do
        command ["filter:authtoken service_host #{node[:ip][:keystone]}",
                 "filter:authtoken auth_host #{node[:ip][:keystone]}",
                 "filter:authtoken auth_uri" <<
                 " http://#{node[:ip][:keystone]}:35357/v2.0",
                 "filter:authtoken admin_tenant_name admin",
                 "filter:authtoken admin_user admin",
                 "filter:authtoken admin_password" <<
                 " #{node[:creds][:admin_password]}"]
end

# Accept incoming connections on glance ports
simple_iptables_rule "cinder" do
    rule "-p tcp -m multiport --dports 3260,8776"
    jump "ACCEPT"
end

libcloud_file_append "/etc/tgt/targets.conf" do
        line "include /etc/cinder/volumes/*"
end

# Populate database
execute "cinder-manage db sync"

# Enable services
%w[
    tgtd openstack-cinder-volume 
    openstack-cinder-scheduler openstack-cinder-api
].each do |srv|
    service srv do 
        action [:enable, :restart]
    end
end


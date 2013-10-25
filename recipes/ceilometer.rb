#
# Cookbook Name:: centos-cloud
# Recipe:: heat
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

centos_cloud_database "ceilometer" do
    password node[:creds][:mysql_password]
end

libcloud_ssh_keys "openstack" do
    data_bag "ssh_keypairs"    
    action [:create, :add] 
end

simple_iptables_rule "ceilometer" do
  rule "-p tcp -m multiport --dports 8777"
  jump "ACCEPT"
end

%w[openstack-ceilometer-api openstack-ceilometer-collector
   openstack-ceilometer-central python-ceilometerclient
].each do |pkg|
        package pkg do
                action :install
        end
end

centos_cloud_config "/etc/ceilometer/ceilometer.conf" do
    command ["database connection mysql://ceilometer:#{node[:creds][:mysql_password]}@localhost/ceilometer",
             "publisher_rpc metering_secret #{node[:creds][:ceilometer_secret]}",
             "keystone_authtoken service_host #{node[:ip][:keystone]}",
             "keystone_authtoken auth_host #{node[:ip][:keystone]}",
             "keystone_authtoken auth_uri http://#{node[:ip][:keystone]}:35357/v2.0",
             "keystone_authtoken admin_tenant_name admin",
             "keystone_authtoken admin_user admin",
             "keystone_authtoken auth_port 35357",
             "keystone_authtoken auth_protocol http",
             "keystone_authtoken admin_password #{node[:creds][:admin_password]}"]
end

execute "ceilometer-dbsync"

%w[openstack-ceilometer-api openstack-ceilometer-central
   openstack-ceilometer-collector
].each do |srv|
    service srv do
        action [:enable, :restart]
    end
end 


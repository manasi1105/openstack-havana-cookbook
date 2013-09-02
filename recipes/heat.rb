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

%w[openstack-heat-api openstack-heat-api-cfn openstack-heat-api-cloudwatch 
   openstack-heat-cli openstack-heat-common openstack-heat-engine].each do |pkg|
    package pkg do
        action :install
    end
end

libcloud_ssh_keys "openstack" do
    data_bag "ssh_keypairs"    
    action [:create, :add] 
end

centos_cloud_database "heat" do
    password node[:mysql][:password]
end

%w[api api-cfn api-cloudwatch].each do |cfg|
    centos_cloud_config "/etc/heat/heat-" + cfg + "-paste.ini" do
        command ["filter:authtoken service_host #{node[:keystone][:ip]}",
                 "filter:authtoken auth_host #{node[:keystone][:ip]}",
                 "filter:authtoken auth_uri http://#{node[:keystone][:ip]}:35357/v2.0",
                 "filter:authtoken admin_tenant_name admin",
                 "filter:authtoken admin_user admin",
                 "filter:authtoken admin_password #{node[:admin][:password]}"]
    end
end

centos_cloud_config "/etc/heat/heat-engine.conf" do
    command ["DEFAULT sql_connection mysql://heat:#{node[:mysql][:password]}@localhost/heat",
"DEFAULT heat_metadata_server_url http://#{node[:heat][:ip]}:8000",
             "DEFAULT heat_waitcondition_server_url http://#{node[:heat][:ip]}:8000/v1/waitcondition",
             "DEFAULT heat_watch_server_url http://#{node[:heat][:ip]}:8003"]
end

execute "heat-db-setup rpm -y -r #{node[:mysql][:password]} -p #{node[:mysql][:password]}"

%w[openstack-heat-api openstack-heat-api-cfn 
   openstack-heat-api-cloudwatch openstack-heat-engine].each do |srv|
    service srv do
        action [:enable, :restart]
    end
end 

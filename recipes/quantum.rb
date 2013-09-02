#
# Cookbook Name:: centos-cloud
# Recipe:: quantum
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
require "socket"

include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::openvswitch"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
    data_bag "ssh_keypairs"    
    action [:create, :add] 
end

centos_cloud_database "quantum" do
    password node[:creds][:mysql_password]
end

#yum_package "iproute" do
#    version "2.6.32-23.el6ost.netns.2"
#end

yum_package "iproute" do
    version "2.6.32-23.el6_4.netns.1"
end
execute "ovs-vsctl add-br br-ex" do
    not_if("ovs-vsctl list-br | grep br-ex")
    action :run
end

template "/etc/sysconfig/network-scripts/ifcfg-" + node[:auto][:external_nic]  do
    not_if do
        File.exists?("/etc/sysconfig/network-scripts/ifcfg-br-ex")
    end
    owner "root"
    group "root"
    mode  "0644"
    source "quantum/ifcfg-eth0.erb"
end

template "/etc/sysconfig/network-scripts/ifcfg-br-ex" do
    not_if do
        File.exists?("/etc/sysconfig/network-scripts/ifcfg-br-ex")
    end
    owner "root"
    group "root"
    mode  "0644"
    source "quantum/ifcfg-br-ex.erb"
end

service "network" do
    action :restart
end

centos_cloud_config "/etc/quantum/metadata_agent.ini" do
    command ["DEFAULT auth_strategy keystone",
             "DEFAULT auth_url http://#{node[:ip][:keystone]}:35357/v2.0",
             "DEFAULT admin_tenant_name admin",
             "DEFAULT admin_user admin",
             "DEFAULT admin_password #{node[:creds][:admin_password]}",
             "DEFAULT metadata_proxy_shared_secret #{node[:creds][:quantum_secret]}",
             "DEFAULT nova_metadata_ip #{node[:ip][:nova]}"]
end

centos_cloud_config "/etc/quantum/dhcp_agent.ini" do
    command ["DEFAULT enable_isolated_metadata True",
             "DEFAULT use_namespaces True",
             "DEFAULT ovs_use_veth True"]
end

centos_cloud_config "/etc/quantum/l3_agent.ini" do
    command ["DEFAULT interface_driver quantum.agent.linux.interface.OVSInterfaceDriver",
             "DEFAULT external_network_bridge br-ex",
             "DEFAULT ovs_use_veth True"]
end

#Support for configurating quantum
template "/root/floating-pool.sh" do
    source "quantum/floating-pool.erb"
    owner "root"
    group "root"
    mode "0744"
end

%w[quantum-dhcp-agent quantum-openvswitch-agent quantum-l3-agent quantum-server quantum-metadata-agent].each do |srv|
    service srv do
        action [:enable, :restart]
    end
end

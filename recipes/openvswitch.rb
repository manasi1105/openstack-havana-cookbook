#
# Cookbook Name:: centos-cloud
# Recipe:: openvswitch
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

package "openstack-quantum-openvswitch" do
        action :install
    end

package "bridge-utils" do
        action :install
end

link "/etc/quantum/plugin.ini" do
  to "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
  link_type :symbolic
end

centos_cloud_config "/etc/quantum/plugin.ini" do
    command ["DATABASE sql_connection mysql://quantum:#{node[:creds][:mysql_password]}@#{node[:ip][:quantum]}/quantum",
             "SECURITYGROUP firewall_driver quantum.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver",
             "OVS enable_tunneling True",
             "OVS tenant_network_type gre",
             "OVS integration_bridge br-int",
             "OVS tunnel_bridge br-tun",
             "OVS tunnel_id_ranges 1:1000",
             "OVS local_ip #{node[:ipaddress]}"]
end

centos_cloud_config "/etc/quantum/quantum.conf" do
    command ["DEFAULT auth_strategy keystone",
             "DEFAULT rpc_backend quantum.openstack.common.rpc.impl_qpid",
             "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
             "DEFAULT allow_overlapping_ips True",
             "DEFAULT core_plugin quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
             "keystone_authtoken auth_host #{node[:ip][:keystone]}",
             "keystone_authtoken admin_tenant_name admin",
             "keystone_authtoken admin_user admin",
             "keystone_authtoken admin_password #{node[:creds][:admin_password]}"]
end

%w[openvswitch quantum-openvswitch-agent quantum-ovs-cleanup].each do |srv|
    service srv do
        action [:enable, :restart]
    end
end

execute "ovs-vsctl add-br br-int" do
    not_if("ovs-vsctl list-br | grep br-int")
    action :run
end

simple_iptables_rule "quantum" do
  rule "-p tcp -m multiport --dports 9696"
  jump "ACCEPT"
end

libcloud_file_append "/etc/sysconfig/network-scripts/ifcfg-br-int" do
        line ["DEVICE=br-int",
              "DEVICETYPE=ovs",
              "TYPE=OVSBridge",
              "ONBOOT=yes",
              "BOOTPROTO=none"]
end



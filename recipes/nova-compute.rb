#
# Cookbook Name:: centos-cloud
# Recipe:: nova-compute
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::openvswitch"
include_recipe "centos_cloud::iptables-policy"

package "openstack-nova-compute" do
    action :install
end

libcloud_ssh_keys node[:creds][:ssh_keypair] do
    data_bag "ssh_keypairs"    
    action [:create, :add] 
end

centos_cloud_config "/etc/nova/nova.conf" do
    command [
        "DEFAULT sql_connection" <<
        " mysql://nova:#{node[:creds][:mysql_password]}@#{node[:ip][:nova]}/nova",
        "DEFAULT rpc_backend nova.openstack.common.rpc.impl_qpid",
        "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
        "DEFAULT network_api_class nova.network.quantumv2.api.API",
        "DEFAULT quantum_auth_strategy keystone",
        "DEFAULT quantum_url http://#{node[:ip][:quantum]}:9696/",
        "DEFAULT quantum_admin_tenant_name admin",
        "DEFAULT quantum_admin_username admin",
        "DEFAULT quantum_admin_password #{node[:creds][:admin_password]}",
        "DEFAULT quantum_admin_auth_url" <<
        " http://#{node[:ip][:quantum]}:35357/v2.0",
        "DEFAULT security_group_api quantum",
        "DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver",
        "DEFAULT libvirt_vif_driver" <<
        " nova.virt.libvirt.vif.LibvirtGenericVIFDriver",
        "DEFAULT auth_strategy keystone",
        "DEFAULT novnc_enabled true",
        "DEFAULT allow_admin_api true",
        "DEFAULT use_deprecated_auth false",
        "DEFAULT dmz_cidr 169.254.169.254/32",
        "DEFAULT metadata_host #{node[:ipaddress]}",
        "DEFAULT metadata_listen 0.0.0.0",
        "DEFAULT enabled_apis ec2,osapi_compute,metadata",
        "DEFAULT novncproxy_base_url" <<
        " http://#{node[:ip][:nova]}:6080/vnc_auto.html",
        "DEFAULT vncserver_proxyclient_address #{node[:ipaddress]}",
        "DEFAULT vncserver_listen 0.0.0.0",
        "DEFAULT resume_guests_state_on_host_boot true",
        "DEFAULT service_quantum_metadata_proxy True",
        "DEFAULT quantum_metadata_proxy_shared_secret" <<
        " #{node[:creds][:quantum_secret]}",
        "DEFAULT glance_api_servers #{node[:ip][:glance]}:9292",
        "keystone_authtoken admin_tenant_name admin",
        "keystone_authtoken admin_user admin",
        "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
        "keystone_authtoken auth_host #{node[:ip][:keystone]}"
    ]
end

%w[libvirtd messagebus openstack-nova-compute].each do |srv|
    service srv do
        action [:enable,:restart]
    end
end

#service "openstack-nova-metadata-api" do
#    not_if do
#        node[:ipaddress] == node[:ip][:nova]
#    end    
#    action [:enable,:restart]
#end

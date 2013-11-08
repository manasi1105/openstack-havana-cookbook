include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

%w[expect nagios php httpd
ganglia ganglia-gmetad ganglia-web].each do |pkg|
  package pkg do
    action :install
  end
end

simple_iptables_rule "nagios" do
  rule "-p tcp -m multiport --dports 80,5666"
  jump "ACCEPT"
end

simple_iptables_rule "ganglia" do
  rule "-p tcp -m multiport --dports 8652,8649"
  jump "ACCEPT"
end

template "/tmp/expect" do
  source "monitoring/expect.erb"
  owner "root"
  group "root"
  mode "0700"
end

execute "/tmp/expect" do
  action :run
end

template "/etc/httpd/conf.d/ganglia.conf" do
  source "monitoring/ganglia.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

%w[httpd nagios gmetad].each do |srv|
  service srv do
    ignore_failure true
    action [:enable, :restart]
  end
end


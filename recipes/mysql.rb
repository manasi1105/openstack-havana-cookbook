#
# Cookbook Name:: centos-cloud
# Recipe:: mysql
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "centos_cloud::iptables-policy"

%w{mysql-server mysql MySQL-python}.each  do |pkg|
  package pkg do
    action :install
  end
end

service "mysqld" do
  action [:enable, :start]
end

simple_iptables_rule "mysql" do
  rule "-p tcp -m multiport --dports 3306"
  jump "ACCEPT"
end

execute "mysqladmin -u root password #{node[:creds][:mysql_password]}" do
  ignore_failure true
  action :run
end

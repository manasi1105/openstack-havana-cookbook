#
# Cookbook Name:: centos-cloud
# Recipe:: repos
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/etc/yum.repos.d/epel.repo" do
  not_if do
    File.exists?("/etc/yum.repos.d/epel.repo")
  end
  source "epel.repo"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/etc/yum.repos.d/epel-openstack-grizzly.repo" do
  not_if do
    File.exists?("/etc/yum.repos.d/epel-openstack-grizzly.repo")
  end
  source "epel-openstack-grizzly.repo"
  mode "0644"
  owner "root"
  group "root"
end

execute "yum clean all"
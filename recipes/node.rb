#
# Cookbook Name:: centos-cloud
# Recipe:: node
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "centos_cloud::nova-compute"
include_recipe "centos_cloud::swift-node"

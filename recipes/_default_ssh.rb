#
# Cookbook Name:: deliver-topology
# Recipe:: _default_ssh
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# Setup ssh provisioning  if it is needed
deliver_topo = node['delivery']['config']['deliver-topology']
deliver_using_ssh = deliver_topo['provisioning_driver'] == 'ssh'

chef_gem 'chef-provisioning-ssh' do
  only_if { deliver_using_ssh }
end

workspace = node['delivery']['workspace']

directory "#{workspace['root']}/chef/provisioning/ssh" do
  mode 00755
  owner 'dbuild'
  group 'dbuild'
  recursive true
  action :create
  only_if { deliver_using_ssh }
end

#
# Cookbook Name:: topology-truck
# Recipe:: _default_ssh
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# Setup ssh provisioning  if it is needed

raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

config = Topo::ConfigurationParameter.new(raw_data.to_hash,stage) if raw_data['topology-truck']

deliver_using_ssh = config.driver_type == 'ssh' if config

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

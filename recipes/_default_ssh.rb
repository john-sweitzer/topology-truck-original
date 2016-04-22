#
# Cookbook Name:: topology-truck
# Recipe:: _default_ssh
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# Setup ssh provisioning  if it is needed
deliver_topo = node['delivery']['config']['topology-truck']

driver = deliver_topo['provision']['driver'] || ''
if driver
    @driver_type = driver.split(":",2)[0]
    else
    @driver_type = "default"
end

deliver_using_ssh = @driver_type == 'ssh'

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

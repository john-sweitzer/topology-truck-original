#
# Cookbook Name:: topology-truck
# Recipe:: provision
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0


include_recipe 'chef-sugar'


driver = node['delivery']['config']['topology-truck']['provisioning_driver']

include_recipe 'topology-truck::_provision_aws' if driver == 'aws'
include_recipe 'topology-truck::_provision_vagrant' if driver == 'vagrant'
include_recipe 'topology-truck::_provision_ssh' if driver == 'ssh'
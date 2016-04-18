#
# Cookbook Name:: deliver-topology
# Recipe:: provision
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# include_recipe 'delivery-truck::provision'

include_recipe 'chef-sugar'

load_delivery_chef_config

driver = node['delivery']['config']['deliver-topology']['provisioning_driver']

include_recipe 'deliver-topology::_provision_aws' if driver == 'aws'
include_recipe 'deliver-topology::_provision_vagrant' if driver == 'vagrant'
include_recipe 'deliver-topology::_provision_ssh' if driver == 'ssh'

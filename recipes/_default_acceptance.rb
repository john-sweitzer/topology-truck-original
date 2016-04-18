#
# Cookbook Name:: deliver-topology
# Recipe:: _default_acceptance
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# The acceptance stage requires some set up before processing the phases.
if node['delivery']['change']['stage'] == 'acceptance'
  include_recipe 'deliver-topology::_default_ssh'
end

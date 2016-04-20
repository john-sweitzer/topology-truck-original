#
# Cookbook Name:: topology-truck
# Recipe:: _default_rehearsal
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# The acceptance stage requires some set up before processing the phases.
if node['delivery']['change']['stage'] == 'rehearsal'
  include_recipe 'topology-truck::_default_ssh'
end

#
# Cookbook Name:: deliver-topology
# Recipe:: _provision_vagrant
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

include_recipe 'chef-sugar'

load_delivery_chef_config

# Setup up some local variable for frequently used value for cleaner code...
project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# Initialize the Vagrant driver after loading it..
require 'chef/provisioning/vagrant_driver'
with_driver 'vagrant'

vagrant_box 'ubuntu64-12.4' do
  url node['project']['stage']['config']['vagrant']['url']
end

# Specify information about our Chef server.
# Chef provisioning uses this information to bootstrap the machine.
with_chef_server(
  Chef::Config[:chef_server_url],
  client_name: Chef::Config[:node_name],
  signing_key_filename: Chef::Config[:client_key],
  ssl_verify_mode: :verify_none,
  verify_api_cert: false
)

#  The recipe is expecting there to be a list of topologies that need machine
#  for  each stage of the pipeline.  Source of the topology list is determined
#  by the details in the config.json file used to configure this pipeline.
#  When this file contains a 'stage_topology' hash those details are used.
#  Otherwise the topology details in the attribute file is used.

topology_list = []
deliver_topo = node['delivery']['config']['deliver-topology']
if deliver_topo
  # Retrieve the topology details from data bags in the Chef server...
  deliver_topo['stage_topology'][stage].each do |topology_name|
    topology = Chef::DataBagItem.load('topologies', topology_name)
    topology_list.push(topology)
  end
else
  # Use a single node topology
  topology_list.push(node[project][stage]['topology'])
end

stage_mach_opts = node[project][stage]['aws']['config']['machine_options']
# Now we are ready to provision the nodes in each of the topologies
topology_list.each do |topology|
  topology_name = topology['name']

  # When there are provisioning details in the topology data bag, extract them
  # and load the values into a structure with symbols rather than string hashes
  if topology['provisioning'] && topology['provisioning']['ssh']
    mach_opts = topology['provisioning']['ssh']['config']['machine_options']
    stage_mach_opts['transport_options'] = mach_opts['transport_options']
    Chef::Log.warn("*** MACHINE OPTIONS.............    #{mach_opts.inspect}")
  end

  # Provision each node in the current topology...
  topology['nodes'].each do |node_details|
    # Prepare a new machine / node for a chef client run...
    machine node_details['name'] do
      action [:setup]
      chef_environment topology_name
      attributes node_details['normal']
      converge false

      run_list node_details['run_list']
      add_machine_options bootstrap_options: {
        key_name: ssh_key['name'],
        key_path: ssh_private_key_path
      }

      add_machine_options stage_mach_opts
    end
  end
end

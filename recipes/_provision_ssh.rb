#
# Cookbook Name:: topology-truck
# Recipe:: _provision_ssh
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
#
# Utility recipe for ::provision

include_recipe 'chef-sugar'

load_delivery_chef_config

# Setup up some local variable for frequently used value for cleaner code...
project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# Initialize the ssh driver after loading it..

require 'chef/provisioning/ssh_driver'
with_driver 'ssh'

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
deliver_topo = node['delivery']['config']['topology-truck']
if deliver_topo
  # Retrieve the topology details from data bags in the Chef server...
  deliver_topo['stage_topology'][stage].each do |topology_name|
    Chef::Log.warn("*** TOPOLOGY NAME.............    #{topology_name} ")
    topology = Chef::DataBagItem.load('topologies', topology_name)
    topology['name'] = topology_name
    topology_list.push(topology)
  end
else
  # Use a single node topology
  topology_list.push(node[project][stage]['topology'])
end

# Now we are ready to provision the nodes in each of the topologies
stage_ssh_mach_opts = node[project][stage]['ssh']['config']['machine_options']
topology_list.each  do |topology|
  topology_name = topology['name']

  # When there are provisioning details in the topology data bag, extract them
  # and load the values into a structure with symbols rather than string hashes
  if topology['provisioning'] && topology['provisioning']['ssh']
    mach_opts = topology['provisioning']['ssh']['config']['machine_options']
    stage_ssh_mach_opts['transport_options'] = mach_opts['transport_options']
    Chef::Log.warn("*** MACHINE OPTIONS.............    #{mach_opts.inspect}")
  end

  Chef::Log.warn("*** TOPOLOGY.............    #{topology.inspect}")

  # Provision each node in the current topology...
  topology['nodes'].each do |node_details|
    Chef::Log.warn("*** TOPOLOGY NAME.............    #{topology_name}")
    Chef::Log.warn("*** TOPOLOGY NAME.............    #{topology['name']}")
    # Prepare a new machine/node for a chef client run...
    machine node_details['name'] do
      action [:setup]
      chef_environment topology['chef_environment']
      attributes node_details['normal']
      converge false

      run_list node_details['run_list']

      # add_machine_options bootstrap_options: {
      #   key_name: ssh_key['name'],
      #   key_path: ssh_private_key_path,
      # }

      # CD: this will need to evolve to set machine_options in general?
      machine_options(
        transport_options: {
          # 'ip_address' => mach_opts['transport_options']['ip_address'],
          'ip_address' => node_details['ssh_host'],
          'username' => stage_ssh_mach_opts['transport_options']['username'],
          'ssh_options' => {
            'password' => stage_ssh_mach_opts['transport_options']['password']
          }
        }
      )
    end
  end
end

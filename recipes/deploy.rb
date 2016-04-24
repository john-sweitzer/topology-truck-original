#
# Cookbook Name:: topology-truck
# Recipe:: deploy
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# include_recipe 'delivery-truck::deploy'
include_recipe 'chef-sugar'

load_delivery_chef_config

# Decrypt the SSH private key Chef provisioning uses to
# connect to the machine and save the key to disk.
ssh_key = encrypted_data_bag_item_for_environment(
  'provisioning-data', 'ssh_key'
)
ssh_private_key_path = File.join(node['delivery']['workspace']['cache'], '.ssh')
directory ssh_private_key_path
file File.join(ssh_private_key_path, "#{ssh_key['name']}.pem") do
  sensitive true
  content ssh_key['private_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0600'
end

# Use these local variable in the rest of the recipe to make the code cleaner...
project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']


# ...  setup the local variable for the configuration configuration details in the config.json


if node['delivery']['config']['topology-truck']
    
    deliver_topo = node['delivery']['config']['topology-truck']
    
    driver = deliver_topo['driver'] || ''
    machine_options = deliver_topo['machine_options'] || {}
    stage_topology = deliver_topo['stage_topology'] || {}
    topologies = stage_topology[stage] || []
    
else
    Chef::Log.warn("Unable to find configuration details for topology-truck so cannot deploy topologies")
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

if topologies
  # Retrieve the topology details from data bags in the Chef server...
  topologies.each do |topology_name|
      
    Chef::Log.warn("*** TOPOLOGY NAME.............    #{topology_name} ")
    
    topo = Topo::Topology.get_topo(topology_name)
    
    if topo
         topology_list.push(topology)
    else
            Chef::Log.warn("Unable to find topology #{topo_name} so cannot configure node")
    end
  end
end

# Now we are ready to provision the nodes in each of the topologies
topology_list.each  do |topology|
  
  topology_name = topology['name']

  # When there are provisioning details in the topology data bag, extract them
  # and load the values into a structure with symbols rather than string hashes
  if topology['provisioning'] && topology['provisioning']['ssh']
    mach_opts = topology['provisioning']['ssh']['config']['machine_options']
    stage_aws_mach_opts['transport_options'] = mach_opts['transport_options']
    Chef::Log.warn("*** MACHINE OPTIONS.............    #{mach_opts.inspect}")
  end

  # Deploy each node in the current topology...
  topology['nodes'].each do |node_details|
    Chef::Log.warn(
      '*** TOPOLOGY NODE(S).............   ' \
      " #{topology_name} NODE:  #{node_details['name']}"
    )
    
    chef_node node_details['name'] do
        chef_environment stage.lowercase    if stage  #todo: logic for topolgoy environments...
        run_list node_details['run_list']   if node_details['run_list']
        tags node_details['tags']           if node_details['tags']
        attributes node_details['normal']   if node_details['normal']
    end
  end
end



# delivery_push_job "deploy_#{node['delivery']['change']['project']}" do
#    command 'chef-client'
#    nodes my_nodes
# end

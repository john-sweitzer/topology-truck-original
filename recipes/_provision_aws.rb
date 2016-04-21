#
# Cookbook Name:: topology-truck
# Recipe:: _provision_aws
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

include_recipe 'chef-sugar'

load_delivery_chef_config

# Decrypt the encryption key that decrypts the database passwords
# and save that file to disk.
# database_passwords_key = encrypted_data_bag_item_for_environment(
#  'provisioning-data', 'database_passwords_key'
# )
# database_passwords_key_path = File.join(
#   node['delivery']['workspace']['cache'],
#   node['delivery']['change']['project']
# )
# directory database_passwords_key_path
# file File.join(database_passwords_key_path, 'database_passwords_key') do
#   sensitive true
#   content database_passwords_key['content']
#   owner node['delivery_builder']['build_user']
#   group node['delivery_builder']['build_user']
#   mode '0664'
# end

# Decrypt the SSH private key Chef provisioning uses to connect to the
# machine and save the key to disk.
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

# Setup up some local variable for frequently used values for cleaner code...
project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']


# ...  setup the local variable for the configuration configuration details in the config.json

if node['delivery']['config']['topology-truck']
    
    deliver_topo = node['delivery']['config']['topology-truck']
    
    driver = deliver_topo['driver'] || ''
    if driver
        @driver_type = driver.split(":",2)[0]
        else
        @driver_type = "default"
    end
    
    machine_options = deliver_topo['machine_options'] || {}
    stage_topology = deliver_topo['stage_topology'] || {}
    topologies = stage_topology[stage] || []
    
    
end
else
Chef::Log.warn("Unable to find configuration details for topology-truck so cannot deploy topologies")
end

if @driver_type.downcase === 'aws'

# Load AWS credentials.
include_recipe "#{cookbook_name}::_aws_creds"

# Initialize the AWS driver after loading it..
require 'chef/provisioning/aws_driver'
with_driver driver

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
        end
        else
        Chef::Log.warn("Unable to find topology #{topo_name} so cannot configure node")
    end
    
end

stage_aws_mach_opts = node[project][stage][@driver_type.downcase]['config']['machine_options']


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

  # Provision each node in the current topology...
  topology['nodes'].each do |node_details|
    Chef::Log.warn(
      '*** TOPOLOGY NODE(S).............   ' \
      " #{topology_name} NODE:  #{node_details['name']}"
    )

    # Prepare a new machine / node for a chef client run...
    machine node_details['name'] do
      action [:setup]
      converge false
      add_machine_options bootstrap_options: {
        key_name: ssh_key['name'],
        key_path: ssh_private_key_path
      }
      add_machine_options stage_aws_mach_opts
    end
  end
end

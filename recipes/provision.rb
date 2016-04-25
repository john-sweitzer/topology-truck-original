#
# Cookbook Name:: topology-truck
# Recipe:: provision  (a phase recipe in a Delivery build-cookbook)
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
#
#



# Setup up some local variable for frequently used values for cleaner code...
project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# Setup local variables for configuration details in the config.json file...

    raw_data = {}
    raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

config = Topo::ConfigurationParameter.new(raw_data.to_hash,stage) if raw_data

Chef::Log.warn("raw_data....         #{raw_data}")
Chef::Log.warn("driver....           #{config.driver()}")
Chef::Log.warn("driver_type....      #{config.driver_type()}")
Chef::Log.warn("machine_options      #{config.machine_options()}")
Chef::Log.warn("topologies....       #{config.topologyList()}")


# Initialize the ssh driver after loading it..
require 'chef/provisioning/ssh_driver'
with_driver 'ssh'


#  The recipe is expecting there to be a list of topologies that need machine
#  for  each stage of the pipeline.  Source of the topology list is determined
#  by the details in the config.json file used to configure this pipeline.
#  When this file contains a 'stage_topology' hash those details are used.
#  Otherwise the topology details in the attribute file is used.

topology_list = []

# Run something in compile phase using delivery chef server
with_server_config do
  Chef::Log.info("Doing stuff like topo truck getting data bags from chef server #{delivery_chef_server[:chef_server_url]}")
  
  # Retrieve the topology details from data bags in the Chef server...
  config.topologyList().each do |topology_name|
      
      Chef::Log.warn("*** TOPOLOGY NAME.............    #{topology_name} ")
      
      topology = Topo::Topology.get_topo(topology_name)
      
      if topology
          topology_list.push(topology)
      else
          Chef::Log.warn("Unable to find topology #{topology_name} so cannot privision any nodes.")
      end
  end
end

# Setup info so cheffish/chef provisioning uses delivery chef server
with_chef_server(
  delivery_chef_server[:chef_server_url], 
  client_name: delivery_chef_server[:options][:client_name],
  signing_key_filename: delivery_chef_server[:options][:signing_key_filename]
  # some specific client.rb options can go here, but not ssl_verify_mode
)

# compile-time code here will execute in local chef server context

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level: :info \n"\
  'verify_api_cert: false'
  
  
  #***************************************
  
  
  # Now we are ready to provision the nodes in each of the topologies
  topology_list.each  do |topology|
      
      topology_name = topology.name()
      
      # When there are provisioning details in the topology data bag, extract them
      # and load the values into a structure with symbols rather than string hashes
      #     if topology['provisioning'] && topology['provisioning']['ssh']
      #    mach_opts = topology['provisioning']['ssh']['config']['machine_options']
      #    stage_aws_mach_opts['transport_options'] = mach_opts['transport_options']
      #    Chef::Log.warn("*** MACHINE OPTIONS.............    #{mach_opts.inspect}")
      #end
      
      # Provision each node in the current topology...
      topology.nodes.each do |node_details|
          
          Chef::Log.warn("***node_details....      #{node_details}")
          Chef::Log.warn(
                         '*** TOPOLOGY NODE(S).............   ' \
                         " #{topology_name} NODE:  #{node_details.name} ip: #{node_details.ssh_host}"
                         )
                         
        # Prepare a new machine / node for a chef client run...
        machine node_details.name do
            action [:setup]
            converge false
            
                         #add_machine_options bootstrap_options: {
                         #        key_name: ssh_key['name'],
                         #        key_path: ssh_private_key_path
                         #    }
                         #    add_machine_options stage_aws_mach_opts
                             
            machine_options(
                    transport_options: {
                            'ip_address' => node_details.ssh_host,
                            'username' => 'vagrant',
                            'ssh_options' => {
                                'password' => 'vagrant'
                            }
                    },
                    convergence_options: {
                            ssl_verify_mode: :verify_none,
                            chef_config: debug_config
                    }
            )
                             
                             
                             
        end
      end
  end
  
  
  
  #****************************************
  
end

ruby_block "do stuff like delivery truck" do
  block do
    # run stuff using delivery chef server in converge phase
    with_server_config do
      Chef::Log.info("Doing stuff like delivery truck pinning envs with chef server #{delivery_chef_server[:chef_server_url]}")
    end
  end
end

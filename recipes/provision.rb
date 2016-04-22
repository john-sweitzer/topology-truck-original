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

 raw_data = node['delivery']['config']['topology-truck']
 config = Config::ConfigurationParameter.new(raw_data.to_hash) if raw_data

Chef::Log.warn("raw_data....    #{raw_data}")
Chef::Log.warn("driver....           #{config.driver()}")
Chef::Log.warn("driver_type....      #{config.driver_type()}")
Chef::Log.warn("machine_options      #{config.machine_options()}")
Chef::Log.warn("topologies....       #{config.topologyList()}")


# Initialize the ssh driver after loading it..
require 'chef/provisioning/ssh_driver'
with_driver 'ssh'

# Run something in compile phase using delivery chef server
with_server_config do
  Chef::Log.info("Doing stuff like topo truck getting data bags from chef server #{delivery_chef_server[:chef_server_url]}")
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

# actual provisioning using delivery chef server
machine 'debugnode' do
  action [:setup]
  chef_environment '_default'
  converge false
  run_list [ 'recipe[yum::default]']
  machine_options(
    transport_options: {
      'ip_address' => '10.0.1.2',
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

ruby_block "do stuff like delivery truck" do
  block do
    # run stuff using delivery chef server in converge phase
    with_server_config do
      Chef::Log.info("Doing stuff like delivery truck pinning envs with chef server #{delivery_chef_server[:chef_server_url]}")
    end
  end
end

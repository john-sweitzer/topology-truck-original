#
# Cookbook Name:: topo
#
# Copyright (c) 2015 ThirdWave Insights, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'chef/data_bag_item'
require_relative './node'

class Topo
  # Handle config.json for topology-truck
  class ConfigurationParameter
    @config = {}


    # class method to get or create Topo instance
    def self.get_topo(name, data_bag = 'topologies')
      unless @topos[name]
        @topos[name] = load_from_bag(name, name, data_bag)

        return nil unless @topos[name]
      end
  
      @topos[name]

    end

    def self.load_from_bag(name, item, data_bag)
      begin
        raw_data = Chef::DataBagItem.load(data_bag, item)
        raw_data['name'] = item if raw_data # Restore name attribute because of chef bug
        topo = Topo::Topology.new(name, raw_data.to_hash) if raw_data
      rescue Net::HTTPServerException => e
        raise unless e.to_s =~ /^404/
      end
      topo
    end

    def initialize(raw_data)

        @raw_data = raw_data['topology-truck'] || {}
    
        #  @attributes = @raw_data['attributes'] || @raw_data['normal'] || {}
      
        if @raw_data['provision']
            driver = @raw_data['provision']['driver'] || ''
            if driver
                @driver_type = driver.split(":",2)[0]
            else
                @driver_type = "default"
            end
          
            @machine_options = deliver_topo['provision']['machine_options'] || {}
        else
            Chef::Log.warn("Unable to find configuration details for topology-truck so cannot deploy topologies")
        end
      
      if @raw_data['stage_topology']
          stage_topology = deliver_topo['stage_topology'] || {}
          stage = node['delivery']['change']['stage'] || 'acceptance'
          @topologies = stage_topology[stage] || []
          end
      
      
    end

    def driver
            return @driver if @driver
            'default'
    end


    def driver_type
      return @driver_type if @driver_type
      'default'
    end

    def machine_options
            return @machine_options if @machine_options
            {}
    end

    def topologyList
            return @topologyList if @topologyList
            []
    end

    
  end
end

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
  # Handle topology data from data bag item
  class Topology
    @topos = {}

    attr_reader :name
    attr_accessor :blueprint

    # class method to get or create Topo instance
    def self.get_topo(name, blueprint = nil, data_bag = 'topologies')
      unless @topos[name]
        @topos[name] = load_from_bag(name, name, data_bag)

        # if specific topology doesnt exist, fallback to blueprint if specified
        if !@topos[name] && blueprint
          @topos[name] = load_from_bag(name, blueprint, data_bag)
        end

        return nil unless @topos[name]
      end

      @topos[name].blueprint = blueprint if blueprint
      @topos[name]
    end

    def self.load_from_bag(name, item, data_bag)
      begin
        raw_data = Chef::DataBagItem.load(data_bag, item)
        topo = Topo::Topology.new(name, raw_data.to_hash) if raw_data
      rescue Net::HTTPServerException => e
        raise unless e.to_s =~ /^404/
      end
      topo
    end

    def initialize(name, raw_data)
      @name = name
      @raw_data = raw_data
      @raw_nodes = @raw_data['nodes'] || []
      @chef_environment = @raw_data['chef_environment']
      @tags = @raw_data['tags']
      @attributes = @raw_data['attributes'] || @raw_data['normal'] || {}
    end

    def nodes
      return @nodes if @nodes
      @nodes = @raw_nodes.map do |node_data|
        Topo::Node.new(inflate_node(node_data))
      end
    end

    # recursive merge that retains all keys
    def prop_merge(hash, other_hash)
      other_hash.each do |key, val|
        if val.is_a?(Hash) && hash[key]
          prop_merge(hash[key], val)
        else
          hash[key] = val
        end
      end
      hash
    end

    # Expand each node in the JSON to contain a complete definition,
    # taking defaults from topology where not defined in the node json
    def inflate_node(node_data)
      node_data['chef_environment'] ||= @chef_environment if @chef_environment
      node_data['attributes'] = inflate_attrs(node_data)
      if @tags
        node_data['tags'] ||= []
        node_data['tags'] |= @tags
      end
      node_data
    end

    def inflate_attrs(node_data)
      attrs = node_data['attributes'] || node_data['normal'] || {}
      attrs['topo'] ||= {}
      attrs['topo']['name'] = @name
      attrs['topo']['blueprint_name'] = @blueprint if @blueprint
      prop_merge(
        Marshal.load(Marshal.dump(@attributes)),
        attrs
      )
    end

    def get_node(name, type = nil)
      node = nodes.find do |n|
        n.name == name
      end

      if !node && type
        # if specific node doesn't exist, look for node of same type
        node = nodes.find do |n|
          n.node_type == type
        end
      end

      node
    end
  end
end

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
require_relative './topology'

class Topo
  # helpers for topo cookbook
  class TopoHelper
    def self.refresh_attributes(node)
      node_type = node['topo']['node_type']
      topo = get_topo(node['topo']['name'], node['topo']['blueprint_name'])

      if topo
        unless set_attrs(node, node_type, topo)
          Chef::Log.warn(
            "Unable to find node '#{node.name}' or node_type " \
            "'#{node_type || 'undefined'}' so cannot get attributes for node")
        end
      end
    end

    def self.get_topo(topo_name, blueprint_name)
      topo = Topo::Topology.get_topo(topo_name, blueprint_name)
      unless topo
        Chef::Log.warn(
          "Unable to find topology '#{topo_name}' or blueprint " \
          "'#{blueprint_name || 'none'}' so cannot get attributes for node")
      end
      topo
    end

    def self.set_attrs(node, node_type, topo)
      topo_node = topo.get_node(node.name, node_type)
      return false unless topo_node
      return false unless topo_node.attributes
      node.normal = topo_node.attributes
      Chef::Log.info(
        "Updated attributes for node using topology '#{topo.name}'")
      true
    end
  end
end

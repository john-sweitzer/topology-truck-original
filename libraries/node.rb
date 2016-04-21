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

class Topo
  #
  class Node
    attr_reader :name, :attributes, :node_type
    attr_reader :chef_environment, :run_list, :tags

    def initialize(node_data)
      @name = node_data['name']
      @chef_environment = node_data['chef_environment']
      @run_list = node_data['run_list']
      normalize_attributes(node_data)
    end

    def normalize_attributes(node_data)
      @attributes = node_data['attributes'] || node_data['normal'] || {}
      @node_type = node_data['node_type'] || @attributes['topo']['node_type']
      @attributes['topo'] ||= {}
      @attributes['topo']['node_type'] ||= @node_type
      @attributes['tags'] = node_data['tags'] if node_data['tags']
    end

    def set_or_merge_attrs(attrs, merge = false)
      node.normal = if merge
                      Chef::Mixin::DeepMerge.merge(node.normal, attrs)
                    else
                      attrs
                    end
    end
  end
end

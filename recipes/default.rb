#
# Cookbook Name:: deliver-topology
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'deliver-topology::_default_acceptance'
include_recipe 'deliver-topology::_default_union'
include_recipe 'deliver-topology::_default_rehearsal'
include_recipe 'deliver-topology::_default_delivered'

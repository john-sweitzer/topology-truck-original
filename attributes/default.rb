#
# Cookbook Name:: build-cookbook
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

project = 'mvt'

default[project]['run_list'] = ['recipe[yum::default]']

%w(acceptance union rehearsal delivered).each do |stage|
  default[project][stage]['ssh']['config'] = {
    machine_options: {
      transport_options: {
        'ip_address' => '10.0.1.2',
        'username' => 'vagrant',
        'password' => 'vagrant'
      }
    }
  }

  default[project][stage]['aws']['config'] = {
    machine_options: {
      bootstrap_options: {
        instance_type: 't2.micro',
        security_group_ids: ['sg-ecaf5b89'],
        subnet_id: 'subnet-bb898bcf'
      },
      convergence_options: {
        ssl_verify_mode: 'verify_none' #:verify_none
      },
      image_id: 'ami-c94856a8',
      ssh_username: 'ubuntu',
      transport_address_location: 'public_ip' #:public_ip
    }
  }

  default[project][stage]['topology'] =
    {
      name: "#{stage}-#{project}",
      version: '_not_used_',
      buildstamp: '_not_used_',
      buildid: '_not_used_',
      strategy: 'direct_to_node',
      chef_environment: 'tp_1n_z',
      tags: [],
      nodes: [
        {
          name:  "#{stage}-#{project}",
          node_type: 'SingleNode',
          tags: [],
          normal: {
            topo: {
              node_type: 'SingleNode',
              name: "#{stage}-#{project}"
            },
            yum: {
              version: '3.2.20',
              newattr: 'tracker'
            }
          },
          run_list: ['recipe[yum::default]']
        }
      ],
      services: []
    }
end

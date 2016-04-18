# Cookbook Name:: topology-truck
# Attributes:: default
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

project = 'mvt'

default[project]['run_list'] = ['recipe[yum::default]']

%w(acceptance union rehearsal delivered).each do |stage|
  default[project][stage]['vagrant']['config'] = {
    #  url: 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box',
    #  vagrant_provider: 'unknown'
    #  machine_options: {
    #    vagrant_options: {
    #      'vm.box'=> 'opscode-ubuntu-12.4',
    #      'network' => ':private_network, {:ip => '33.33.33.14'}'
    #      'hostname' => 'hostnameone'
    #    },
    #    convergence_options: {
    #      ssl_verify_mode: 'verify_none' #:verify_none
    #    },
    #    transport_address_location: 'private_ip' #:public_ip
    # }
  }
end

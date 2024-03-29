#
# Cookbook Name:: topology-truck
# Recipe:: _aws_creds
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

with_server_config do
  # Decrypt the AWS credentials from the data bag.
  aws_creds = encrypted_data_bag_item_for_environment(
    'provisioning-data', 'aws_creds'
  )

  # Create a string to hold the contents of the credentials file.
  aws_config_contents = <<-EOF
  [#{aws_creds['profile']}]
  region = #{aws_creds['region']}
  aws_access_key_id = #{aws_creds['access_key_id']}
  aws_secret_access_key = #{aws_creds['secret_access_key']}
  EOF

  # Compute the path to the credentials file.
  aws_config_filename = File.join(
    node['delivery']['workspace']['cache'],
    node['delivery']['change']['project'], 'aws_config'
  )

  # Ensure parent directory exists.
  directory File.join(
    node['delivery']['workspace']['cache'],
    node['delivery']['change']['project']
  )

  # Write the AWS credentials to disk.
  # Alternatively, you can use the template resource.
  file aws_config_filename do
    sensitive true
    content aws_config_contents
  end

  # Set the AWS_CONFIG_FILE environment variable.
  # Chef provisioning reads this environment variable to
  # access the AWS credentials file.
  ENV['AWS_CONFIG_FILE'] = aws_config_filename
end

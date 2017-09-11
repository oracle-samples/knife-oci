# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'oci'

SERVER_CREATE_OUTPUT_DIRECTORY = 'test_output/server_create/'.freeze

def should_mock_response
  ENV['MOCK_OCI'] && ENV['MOCK_OCI'] != 'false'
end

def run_server_create(param_hash, file)
  puts "Running integ test #{file}..."
  if should_mock_response
    puts '++++++ Response is being mocked. To stop mocking, unset MOCK_OCI. ++++++'
    shell = double(stdout: File.open(SERVER_CREATE_OUTPUT_DIRECTORY + file + '.txt', 'rb').read)
  else
    params = param_hash.map { |k, v| "#{k} #{v}" }.join(' ')
    shell = write_command_to_file("server create #{params}", file, SERVER_CREATE_OUTPUT_DIRECTORY)
  end
  @latest_output = shell.stdout
  puts "Warning: command output is empty.  Check #{SERVER_CREATE_OUTPUT_DIRECTORY + file + '.txt'} for error messages" if @latest_output.to_s.empty?
  shell
end

def run_server_delete(param_hash, file)
  puts "Running integ test #{file}..."
  if should_mock_response
    puts '++++++ Response is being mocked. To stop mocking, unset MOCK_OCI. ++++++'
    shell = double(stdout: File.open(SERVER_CREATE_OUTPUT_DIRECTORY + file + '.txt', 'rb').read)
  else
    params = param_hash.map { |k, v| "#{k} #{v}" }.join(' ')
    shell = write_command_to_file("server delete #{params}", file, SERVER_CREATE_OUTPUT_DIRECTORY)
  end
  @latest_output = shell.stdout
  puts "Warning: command output is empty.  Check #{SERVER_CREATE_OUTPUT_DIRECTORY + file + '.txt'} for error messages" if @latest_output.to_s.empty?
  shell
end

def validate_output(shell, params)
  expect(shell.stdout).to include(params['--availability-domain'])
  expect(shell.stdout).to include(params['--image-id'])
  expect(shell.stdout).to include('is now running')
  expect(shell.stdout).to include('Public IP Address:')
  expect(shell.stdout).to include('Chef Client finished')
end

def validate_delete_output(shell, chef_node_name)
  expect(shell.stdout).to include("Deleted Chef node '#{chef_node_name}'")
end

def delete_and_purge
  return if @latest_output.nil?
  # delete the instance using default chef node name
  output = @latest_output
  @latest_output = nil
  match = output.match("Instance ID:\s(.*)")
  return unless match && match.length > 1
  instance_id = match[1]
  chef_node_name = output.match("Bootstrapping with node name '(.+)'")[1]
  puts "Clean Up: Terminating instance #{instance_id}."
  yield instance_id, chef_node_name
end

describe 'server create command' do
  let(:min_params) do
    {
      '--availability-domain' => availability_domain,
      '--compartment-id' => compartment_id,
      '--subnet-id' => subnet_id,
      '--shape' => shape,
      '--image-id' => 'Must be set for each run.',
      '--oci-config-file' => config_file_path,
      '--oci-profile' => profile,
      '--ssh-authorized-keys-file' => public_ssh_key_file,
      '--identity-file' => private_key_file,
      '--ssh-user' => 'opc',
      '--yes' => true
    }
  end

  let(:extra_params) do
    {
      '--display-name' => 'knife_integ_instance',
      '--hostname-label' => 'myintegtesthostname',
      '--metadata' => '\'{"key1":"value1", "key2":"value2"}\'',
      '--user-data-file' => 'spec/resources/example_user_data.txt'
    }
  end

  let(:min_delete_params) do
    {
      '--compartment-id' => compartment_id,
      '--oci-config-file' => config_file_path,
      '--oci-profile' => profile,
      '--yes' => true
    }
  end

  it 'can create an Oracle Linux instance with min params' do
    params = min_params
    params['--image-id'] = oracle_linux_image_id
    puts params.inspect
    shell = run_server_create(params, 'test_oracle_linux_min_params')
    validate_output(shell, params)

    delete_and_purge do |instance_id, chef_node_name|
      # delete the instance using default chef node name
      params = min_delete_params
      params['--instance-id'] = instance_id
      params['--purge'] = true
      shell = run_server_delete(params, 'test_oracle_linux_delete_with_purge')
      validate_delete_output(shell, chef_node_name)
    end
  end

  it 'can create an Oracle Linux instance with all params' do
    params = min_params.merge(extra_params)
    params['--image-id'] = oracle_linux_image_id
    shell = run_server_create(params, 'test_oracle_linux_all_params')
    validate_output(shell, params)
    expect(shell.stdout).to include(params['--display-name'])
    delete_and_purge do |instance_id|
      # delete the instance using default chef node name
      params = min_delete_params
      params['--instance-id'] = instance_id
      params['--purge'] = true
      shell = run_server_delete(params, 'test_oracle_linux_delete_with_non_default_displayname')
      validate_delete_output(shell, extra_params['--display-name'])
    end
  end

  it 'can create an Ubuntu instance' do
    params = min_params
    params['--image-id'] = ubuntu_image_id
    params['--ssh-user'] = 'ubuntu'
    shell = run_server_create(params, 'test_ubuntu')
    validate_output(shell, params)
    delete_and_purge do |instance_id, chef_node_name|
      # delete the instance using specified chef node name
      params = min_delete_params
      params['--instance-id'] = instance_id
      params['--purge'] = true
      params['--node-name'] = chef_node_name
      shell = run_server_delete(params, 'test_ubuntu_delete')
      validate_delete_output(shell, chef_node_name)
    end
  end
end

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'oraclebmc'

SERVER_CREATE_OUTPUT_DIRECTORY = 'test_output/server_create/'.freeze

def should_mock_response
  ENV['MOCK_BMCS'] && ENV['MOCK_BMCS'] != 'false'
end

def run_server_create(param_hash, file)
  puts "Running integ test #{file}..."
  if should_mock_response
    puts '++++++ Response is being mocked. To stock mocking, unset MOCK_BMCS. ++++++'
    shell = double(stdout: File.open(SERVER_CREATE_OUTPUT_DIRECTORY + file + '.txt', 'rb').read)
  else
    params = param_hash.map { |k, v| "#{k} #{v}" }.join(' ')
    shell = write_command_to_file("server create #{params}", file, SERVER_CREATE_OUTPUT_DIRECTORY)
  end
  @latest_output = shell.stdout
  shell
end

def validate_output(shell, params)
  expect(shell.stdout).to include(params['--availability-domain'])
  expect(shell.stdout).to include(params['--image-id'])
  expect(shell.stdout).to include('is now running')
  expect(shell.stdout).to include('Public IP Address:')
  expect(shell.stdout).to include('Chef Client finished')
end

describe 'server create command' do
  let(:min_params) do
    {
      '--availability-domain' => availability_domain,
      '--compartment-id' => compartment_id,
      '--subnet-id' => subnet_id,
      '--shape' => 'VM.Standard1.1',
      '--image-id' => 'Must be set for each run.',
      '--bmcs-config-file' => config_file_path,
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

  after(:each) do
    unless @latest_output.nil? || should_mock_response
      output = @latest_output
      @latest_output = nil

      match = output.match("Instance ID:\s(.*)")
      if match && match.length > 1
        instance_id = match[1]
        puts "Clean Up: Terminating instance #{instance_id}."
        client = OracleBMC::Core::ComputeClient.new(config: OracleBMC::ConfigFileLoader.load_config(config_file_location: config_file_path))
        client.terminate_instance(instance_id)
      end
    end
  end

  it 'can create Oracle-Linux-7.3-2017.04.18-0 instance with min params' do
    params = min_params
    params['--image-id'] = 'ocid1.image.oc1.phx.aaaaaaaaqutj4qjxihpl4mboabsa27mrpusygv6gurp47kat5z7vljmq3puq'
    shell = run_server_create(params, 'oracle_linux_7_min_params')
    validate_output(shell, params)
  end

  it 'can create Oracle-Linux-7.3-2017.04.18-0 instance with all params' do
    params = min_params.merge(extra_params)
    params['--image-id'] = 'ocid1.image.oc1.phx.aaaaaaaaqutj4qjxihpl4mboabsa27mrpusygv6gurp47kat5z7vljmq3puq'
    shell = run_server_create(params, 'oracle_linux_7_all_params')
    validate_output(shell, params)
    expect(shell.stdout).to include(params['--display-name'])
  end

  it 'can create Oracle-Linux-6.8-2017.03.02-0 instance' do
    params = min_params
    params['--image-id'] = 'ocid1.image.oc1.phx.aaaaaaaawrkdsfnl327clq3cszhhjujxl5rh6htn2arcz5icdih36ohyip2q'
    shell = run_server_create(params, 'oracle_linux_6')
    validate_output(shell, params)
  end

  it 'can create a CentOS-7-2017.04.18-0 instance' do
    params = min_params
    params['--image-id'] = 'ocid1.image.oc1.phx.aaaaaaaaamx6ta37uxltor6n5lxfgd5lkb3lwmoqurlpn2x4dz5ockekiuea'
    shell = run_server_create(params, 'centos_7')
    validate_output(shell, params)
  end

  it 'can create a CentOS-6.8-2017.02.03-0 instance' do
    params = min_params
    params['--image-id'] = 'ocid1.image.oc1.phx.aaaaaaaa52piclnuizazimz7kekehatfcxkozzf3deqelfmjc5qeiqkrpryq'
    shell = run_server_create(params, 'centos_6')
    validate_output(shell, params)
  end

  it 'can create a Canonical-Ubuntu-16.04-2017.05.16-0 instance' do
    params = min_params
    params['--image-id'] = 'ocid1.image.oc1.phx.aaaaaaaae3a3oedsmmwsqu4dsrzntekefgq7vosngn4r6u6n5mis7dwpxxpa'
    params['--ssh-user'] = 'ubuntu'
    shell = run_server_create(params, 'ubuntu_16')
    validate_output(shell, params)
  end
end

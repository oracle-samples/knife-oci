# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'oraclebmc'

LIST_OUTPUT_DIRECTORY = 'test_output/list_commands/'.freeze

def run_command(command, param_hash, file)
  params = param_hash.map { |k, v| "#{k} #{v}" }.join(' ')
  shell = write_command_to_file("#{command} #{params}", file, LIST_OUTPUT_DIRECTORY)
  shell
end

def validate_output(shell, params)
  expect(shell.stdout).to include(params['--availability-domain'])
  expect(shell.stdout).to include(params['--image-id'])
  expect(shell.stdout).to include('is now running')
  expect(shell.stdout).to include('Public IP Address:')
  expect(shell.stdout).to include('Chef Client finished')
end

describe 'list commands' do
  let(:params_only_bmcs_config) do
    {
      '--bmcs-config-file' => config_file_path,
      '--bmcs-profile' => profile
    }
  end

  let(:params_only_knife_config) do
    {
      '--config' => KNIFE_CONFIG_FILE
    }
  end

  let(:params_with_compartment) do
    {
      '--bmcs-config-file' => config_file_path,
      '--bmcs-profile' => profile,
      '--compartment-id' => compartment_id
    }
  end

  it 'can list availability domains' do
    shell = run_command('ad list', params_only_bmcs_config, 'ad_list')
    expect(shell.stdout).to include('AD-2')
  end

  it 'can point to bmcs config and compartment from knife config' do
    shell = run_command('image list', params_only_knife_config, 'image_list_with_knife_config')
    expect(shell.stdout).to include('Display Name')
    expect(shell.stdout).to include('ocid1.image')
  end

  it 'can list images' do
    shell = run_command('image list', params_with_compartment, 'image_list')
    expect(shell.stdout).to include('Display Name')
    expect(shell.stdout).to include('ocid1.image')
    expect(shell.stderr).not_to include('This list has been truncated.')
  end

  it 'can list images with limit' do
    params_with_compartment['--limit'] = '1'
    shell = run_command('image list', params_with_compartment, 'image_list_with_limit')
    expect(shell.stdout).to include('Display Name')
    expect(shell.stdout).to include('ocid1.image')
    expect(shell.stderr).to include('This list has been truncated.')
  end

  it 'can list images with altnernate format' do
    params_with_compartment['--format'] = 'text'
    shell = run_command('image list', params_with_compartment, 'image_list_with_text_format')
    expect(shell.stdout).not_to include('Display Name')
    expect(shell.stdout).to include('createImageAllowed:')
    expect(shell.stderr).not_to include('This list has been truncated.')
  end

  it 'can list instances' do
    shell = run_command('server list', params_with_compartment, 'server_list')
    expect(shell.stdout).to include('Display Name')
    expect(shell.stdout).to include('State')
    expect(shell.stderr).not_to include('This list has been truncated.')
  end
end

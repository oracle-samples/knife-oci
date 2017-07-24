# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'

OUTPUT_DIRECTORY = 'test_output/help/'.freeze

def write_help(subcommand, file)
  shell = write_command_to_file("#{subcommand} --help", file, OUTPUT_DIRECTORY)
  expect(shell.stdout).to include('--help')
  shell
end

describe 'show help for each command' do
  it 'bmcs displays a help message' do
    write_help('', 'bmcs')
  end

  it 'server create displays a help message' do
    write_help('server create', 'server_create')
  end

  it 'image list displays a help message' do
    write_help('image list', 'image_list')
  end

  it 'shape list displays a help message' do
    write_help('shape list', 'shape_list')
  end

  it 'ad list displays a help message' do
    write_help('ad list', 'ad_list')
  end

  it 'server list displays a help message' do
    write_help('server list', 'server_list')
  end

  it 'compartment list displays a help message' do
    write_help('compartment list', 'compartment_list')
  end

  it 'subnet list displays a help message' do
    write_help('subnet list', 'subnet_list')
  end

  it 'vcn list displays a help message' do
    write_help('vcn list', 'vcn_list')
  end
end

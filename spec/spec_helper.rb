# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'simplecov'
SimpleCov.start do
  add_filter '/chef-repo/'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'chef'
require 'chef/knife'
require 'rspec'
require 'mixlib/shellout'
require 'chef/mixin/shell_out'

KNIFE_CONFIG_FILE = 'spec/resources/knife.rb'.freeze

# Dummy public SSH key - not used with any actual instances.
DUMMY_PUBLIC_KEY_FILE = 'spec/resources/dummy_ssh_key.pub'.freeze

# Dummy private SSH key - not used with any actual instances.
DUMMY_PRIVATE_KEY_FILE = 'spec/resources/dummy_ssh_key'.freeze

# Config file used for unit test - the info it contains will not work
# with a real tenancy.
DUMMY_CONFIG_FILE = 'spec/resources/config_for_unit_tests'.freeze

def compartment_id
  # Example value: ocid1.compartment.oc1..aaaaaaaa7x9zzwkqlcyupl6msnblrhffavz6bu6phk7q265kfsil3ileabcq
  ENV['KNIFE_BMCS_COMPARTMENT']
end

def availability_domain
  # Example value: IxGV:US-ASHBURN-AD-2
  ENV['KNIFE_BMCS_AD']
end

def config_file_path
  # Example value: ~/.oraclebmc/config
  ENV['KNIFE_BMCS_CONFIG_FILE']
end

def profile
  # Example value: DEFAULT
  ENV['KNIFE_BMCS_PROFILE']
end

def subnet_id
  # Example value: ocid1.subnet.oc1.iad.aaaaaaaacuqa4rii7bwqyanrarfmqgsz6qptljsvqijcpcspfaty4lab8nza
  ENV['KNIFE_BMCS_SUBNET']
end

def shape
  # Example value: VM.Standard1.1
  ENV['KNIFE_BMCS_SHAPE']
end

def oracle_linux_image_id
  # Example value: ocid1.image.oc1.iad.aaaaaaaah2d5y4jlyi6q5mus4ihabunzdzuiwmuc3pequv27jfkc5eb4ylcq
  ENV['KNIFE_BMCS_ORACLE_LINUX_ID']
end

def ubuntu_image_id
  # Example value: ocid1.image.oc1.iad.aaaaaaaa25xqs7rqfkf7ukgwnpzvyhbg3qd4rplu7yl5tpnmdkzzeudr3s2a
  ENV['KNIFE_BMCS_UBUNTU_ID']
end

def public_ssh_key_file
  # Example value: ~/.keys/instance_keys.pub
  ENV['KNIFE_BMCS_PUBLIC_SSH_KEY_FILE']
end

def private_key_file
  # Example value: ~/.keys/instance_keys
  ENV['KNIFE_BMCS_PRIVATE_KEY_FILE']
end

RSpec.configure do |rspec|
  # Calls to exit(1) produce a SystemExit, which will cause rspec to stop executing any remaining tests and report success.
  # This will convert SystemExit to a RuntimeError such that tests will fail in that case.
  rspec.around(:example) do |ex|
    begin
      ex.run
    rescue SystemExit
      raise 'Unexpected SystemExit called.'
    end
  end
end

def write_command_to_file(subcommand, file, directory)
  command = "knife bmcs #{subcommand}"
  shell = Mixlib::ShellOut.new(command)
  shell.run_command

  output = command
  output = output + "\n\n" + shell.stdout unless shell.stdout.empty?
  output = output + "\n\n+++ STDERR +++\n\n" + shell.stderr unless shell.stderr.empty?

  Dir.mkdir(directory) unless Dir.exist?(directory)
  File.open(File.join(directory, file + '.txt'), 'w') { |f| f.write(output) }
  shell
end

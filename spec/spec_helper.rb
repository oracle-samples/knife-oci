# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

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
  ENV['KNIFE_BMCS_COMPARTMENT']
end

def availability_domain
  ENV['KNIFE_BMCS_AD']
end

def config_file_path
  ENV['KNIFE_BMCS_CONFIG_FILE']
end

def subnet_id
  ENV['KNIFE_BMCS_SUBNET']
end

def public_ssh_key_file
  ENV['KNIFE_BMCS_PUBLIC_SSH_KEY_FILE']
end

def private_key_file
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

  File.open(File.join(directory, file + '.txt'), 'w') { |f| f.write(output) }
  shell
end

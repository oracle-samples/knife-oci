# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_create'
require 'oraclebmc'
require './spec/spec_helper'

# rubocop:disable Metrics/BlockLength
describe Chef::Knife::BmcsServerCreate do
  let(:knife_bmcs_server_create) { Chef::Knife::BmcsServerCreate.new }

  describe 'run server create' do
    let(:instance) do
      double(availability_domain: 'ad1',
             compartment_id: 'compartmentA',
             display_name: 'myname',
             id: '12345',
             image_id: 'myimage',
             region: 'phx',
             shape: 'round',
             subnet_id: 'supersubnet')
    end

    let(:vnic) do
      double(public_ip: '123.456.789.101',
             private_ip: '10.0.0.0',
             hostname_label: 'myhostname')
    end

    let(:min_config) do
      {
        availability_domain: 'ad1',
        compartment_id: 'compartmentA',
        image_id: 'myimage',
        shape: 'round',
        subnet_id: 'supersubnet',
        ssh_authorized_keys_file: DUMMY_PUBLIC_KEY_FILE,
        identity_file: DUMMY_PRIVATE_KEY_FILE
      }
    end

    it 'should list missing required params' do
      expect(knife_bmcs_server_create.ui).to receive(:error).with('Missing the following required parameters: availability-domain, image-id, shape, subnet-id, identity-file')
      expect { knife_bmcs_server_create.run }.to raise_error(SystemExit)
    end

    it 'runs with minimal parameters' do
      knife_bmcs_server_create.config = min_config

      allow(knife_bmcs_server_create.compute_client).to receive(:launch_instance).and_return(double(data: instance))
      allow(knife_bmcs_server_create).to receive(:wait_for_ssh).and_return(true)
      allow(knife_bmcs_server_create).to receive(:wait_for_instance_running).and_return(instance)
      allow(knife_bmcs_server_create).to receive(:get_vnic).and_return(vnic)
      allow(knife_bmcs_server_create).to receive(:wait_to_stabilize)
      expect(knife_bmcs_server_create).to receive(:bootstrap)
      expect(knife_bmcs_server_create.ui).to receive(:msg).at_least(10).times
      expect(knife_bmcs_server_create).to receive(:get_vnic).with('12345', 'compartmentA')

      knife_bmcs_server_create.run
    end

    it 'should show error when file not found' do
      knife_bmcs_server_create.config[:user_data_file] = 'notarealfile.dat'
      expect { knife_bmcs_server_create.get_file_content(:user_data_file) }.to raise_error(Errno::ENOENT)
    end

    it 'should expand file paths' do
      knife_bmcs_server_create.config[:user_data_file] = '~/notarealfile.dat'
      expect { knife_bmcs_server_create.get_file_content(:user_data_file) }.to raise_error do |error|
        expect(error.to_s).to include(ENV['USER'])
      end
    end
  end

  describe 'bmcs_config' do
    it 'should load default values' do
      expect(OracleBMC::ConfigFileLoader).to receive(:load_config).with(config_file_location: '~/.oraclebmc/config',
                                                                        profile_name: 'DEFAULT').and_return(OracleBMC::Config.new)
      knife_bmcs_server_create.bmcs_config
    end

    it 'should load values from command line' do
      knife_bmcs_server_create.config[:bmcs_config_file] = 'myconfig'
      knife_bmcs_server_create.config[:bmcs_profile] = 'nobody'
      expect(OracleBMC::ConfigFileLoader).to receive(:load_config).with(config_file_location: 'myconfig',
                                                                        profile_name: 'nobody').and_return(OracleBMC::Config.new)
      knife_bmcs_server_create.bmcs_config
    end

    it 'should show error when file not found' do
      knife_bmcs_server_create.config[:bmcs_config_file] = 'notarealconfigfile'
      expect { knife_bmcs_server_create.bmcs_config }.to raise_error.with_message(/Config file does not exist/)
    end

    it 'should show error when profile not found' do
      knife_bmcs_server_create.config[:bmcs_config_file] = DUMMY_CONFIG_FILE
      knife_bmcs_server_create.config[:bmcs_profile] = 'notarealprofile'
      expect { knife_bmcs_server_create.bmcs_config }.to raise_error.with_message(/Profile not found/)
    end

    it 'should add to user agent' do
      knife_bmcs_server_create.config[:bmcs_config_file] = DUMMY_CONFIG_FILE
      expect(knife_bmcs_server_create.bmcs_config.additional_user_agent).to eq 'Oracle-ChefKnifeBMCS/1.0.0'
    end
  end

  describe 'wait_for_ssh' do
    it 'should return false on timeout' do
      allow(knife_bmcs_server_create).to receive(:can_ssh).and_return(false)
      expect(knife_bmcs_server_create).to receive(:show_progress).at_least(10).times
      expect(knife_bmcs_server_create.wait_for_ssh('111.111.111.111', 22, 0.01, 0.5)).to eq(false)
    end

    it 'should return immediately on success' do
      allow(knife_bmcs_server_create).to receive(:can_ssh).and_return(true)
      expect(knife_bmcs_server_create).to receive(:show_progress).exactly(0).times
      expect(knife_bmcs_server_create.wait_for_ssh('111.111.111.111', 22, 0.01, 0.5)).to eq(true)
    end
  end

  describe 'merge_metadata' do
    it 'should merge metadata from all sources' do
      knife_bmcs_server_create.config[:ssh_authorized_keys_file] = DUMMY_PUBLIC_KEY_FILE
      knife_bmcs_server_create.config[:user_data_file] = 'spec/resources/example_user_data.txt'
      knife_bmcs_server_create.config[:metadata] = '{"key1":"value1", "key2":"value2"}'
      metadata = knife_bmcs_server_create.merge_metadata
      expect(metadata.keys.length).to eq 4
      expect(metadata).to have_key('ssh_authorized_keys')
      expect(metadata['ssh_authorized_keys'].length).to be > 0
      expect(metadata['user_data']).to eq 'IyEvYmluL2Jhc2gKCmVjaG8gIlRoaXMgd2FzIGNyZWF0ZWQgYnkgQ2xvdWRJbml0IHVzZXIgZGF0YS4iID4+IHVzZXJfZGF0YV9leGFtcGxlX291dHB1dC50eHQ='
      expect(metadata['key1']).to eq 'value1'
      expect(metadata['key2']).to eq 'value2'
    end

    it 'should merge metadata from ssh keys only' do
      knife_bmcs_server_create.config[:ssh_authorized_keys_file] = DUMMY_PUBLIC_KEY_FILE
      metadata = knife_bmcs_server_create.merge_metadata
      expect(metadata.keys.length).to eq 1
      expect(metadata).to have_key('ssh_authorized_keys')
      expect(metadata['ssh_authorized_keys'].length).to be > 0
    end

    it 'should merge metadata from metadata param only' do
      knife_bmcs_server_create.config[:metadata] = '{"user_data":"mydata", "ssh_authorized_keys":"mykeys"}'
      metadata = knife_bmcs_server_create.merge_metadata
      expect(metadata.keys.length).to eq 2
      expect(metadata).to have_key('ssh_authorized_keys')
      expect(metadata['ssh_authorized_keys']).to eq 'mykeys'
      expect(metadata['user_data']).to eq 'mydata'
    end

    it 'should show error if metadata is not in json format' do
      knife_bmcs_server_create.config[:metadata] = '{"key1":"value1", "key2":"value2" invalid}'
      expect(knife_bmcs_server_create.ui).to receive(:error).with('Metadata value must be in JSON format. Example: \'{"key1":"value1", "key2":"value2"}\'')
      expect { knife_bmcs_server_create.merge_metadata }.to raise_error(SystemExit)
    end

    it 'should show error when user_data given twice' do
      knife_bmcs_server_create.config[:metadata] = '{"user_data":"mydata", "ssh_authorized_keys":"mykeys"}'
      knife_bmcs_server_create.config[:user_data_file] = 'spec/resources/example_user_data.txt'
      expect(knife_bmcs_server_create.ui).to receive(:error)
      expect { knife_bmcs_server_create.merge_metadata }.to raise_error(SystemExit)
    end

    it 'should show error when ssh_authorized_keys given twice' do
      knife_bmcs_server_create.config[:metadata] = '{"user_data":"mydata", "ssh_authorized_keys":"mykeys"}'
      knife_bmcs_server_create.config[:ssh_authorized_keys_file] = DUMMY_PUBLIC_KEY_FILE
      expect(knife_bmcs_server_create.ui).to receive(:error)
      expect { knife_bmcs_server_create.merge_metadata }.to raise_error(SystemExit)
    end
  end

  describe 'vnic details' do
    let(:instance) do
      double(availability_domain: 'ad1',
             compartment_id: 'compartmentA',
             display_name: 'myname',
             id: '12345',
             image_id: 'myimage',
             region: 'phx',
             shape: 'round',
             subnet_id: 'supersubnet')
    end

    let(:vnic) do
      double(public_ip: '123.456.789.101',
             private_ip: '10.1.2.3',
             hostname_label: 'myhostname')
    end

    let(:config) do
      {
        availability_domain: 'ad1',
        compartment_id: 'compartmentA',
        image_id: 'myimage',
        shape: 'round',
        subnet_id: 'supersubnet',
        ssh_authorized_keys_file: DUMMY_PUBLIC_KEY_FILE,
        identity_file: DUMMY_PRIVATE_KEY_FILE
      }
    end

    context 'bool_arg should properly categorize input data' do
      it 'handles valid input data' do
        expect(knife_bmcs_server_create.bool_arg('yes')).to equal(true)
        expect(knife_bmcs_server_create.bool_arg('true')).to equal(true)
        expect(knife_bmcs_server_create.bool_arg('false')).to equal(false)
        expect(knife_bmcs_server_create.bool_arg('no')).to equal(false)
        expect(knife_bmcs_server_create.bool_arg(nil)).to equal(nil)
      end
      it 'handles invalid input data' do
        expect(knife_bmcs_server_create.ui).to receive(:error).with('Boolean arguments must be one of: yes, no, true, false')
        expect { knife_bmcs_server_create.bool_arg('invalid-input') }.to raise_error(SystemExit)

        expect(knife_bmcs_server_create.ui).to receive(:error).with('Boolean arguments must be one of: yes, no, true, false')
        expect { knife_bmcs_server_create.bool_arg(true) }.to raise_error(SystemExit)
      end
    end

    it 'should ensure vnic details are used' do
      knife_bmcs_server_create.config = config
      knife_bmcs_server_create.config[:assign_public_ip] = 'true'
      knife_bmcs_server_create.config[:private_ip] = '10.1.2.3'
      vnic_details = knife_bmcs_server_create.make_vnic_details
      expect(vnic_details.assign_public_ip).to equal(true)
      expect(vnic_details.private_ip).to eq '10.1.2.3'
    end

    it 'passes vnic details to launch_instance' do
      knife_bmcs_server_create.config = config
      knife_bmcs_server_create.config[:assign_public_ip] = 'false'
      knife_bmcs_server_create.config[:private_ip] = '10.1.2.3'

      allow(knife_bmcs_server_create.compute_client).to receive(:launch_instance).and_return(double(data: instance))
      allow(knife_bmcs_server_create).to receive(:wait_for_ssh).and_return(true)
      allow(knife_bmcs_server_create).to receive(:wait_for_instance_running).and_return(instance)
      allow(knife_bmcs_server_create).to receive(:get_vnic).and_return(vnic)
      allow(knife_bmcs_server_create).to receive(:wait_to_stabilize)
      expect(knife_bmcs_server_create).to receive(:bootstrap)
      expect(knife_bmcs_server_create.ui).to receive(:msg).at_least(10).times
      expect(knife_bmcs_server_create).to receive(:get_vnic).with('12345', 'compartmentA')
      expect(knife_bmcs_server_create).to receive(:make_vnic_details)

      knife_bmcs_server_create.run
    end

    it 'get_bootstrap_ip chooses correct interface' do
      knife_bmcs_server_create.config = config

      knife_bmcs_server_create.config[:assign_public_ip] = 'false'
      expect(knife_bmcs_server_create.get_bootstrap_ip(vnic)).to eq '10.1.2.3'

      knife_bmcs_server_create.config[:assign_public_ip] = 'true'
      expect(knife_bmcs_server_create.get_bootstrap_ip(vnic)).to eq '123.456.789.101'

      knife_bmcs_server_create.config[:assign_public_ip] = 'true'
      knife_bmcs_server_create.config[:use_private_ip] = true
      expect(knife_bmcs_server_create.get_bootstrap_ip(vnic)).to eq '10.1.2.3'

      knife_bmcs_server_create.config.delete(:assign_public_ip)
      knife_bmcs_server_create.config.delete(:use_private_ip)
      expect(knife_bmcs_server_create.get_bootstrap_ip(vnic)).to eq '123.456.789.101'

      knife_bmcs_server_create.config.delete(:assign_public_ip)
      knife_bmcs_server_create.config[:use_private_ip] = false
      expect(knife_bmcs_server_create.get_bootstrap_ip(vnic)).to eq '123.456.789.101'
    end
  end
end

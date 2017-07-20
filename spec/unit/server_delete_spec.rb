# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_delete'
require 'oraclebmc'
require './spec/spec_helper'

describe Chef::Knife::BmcsServerDelete do
  let(:knife_bmcs_server_delete) { Chef::Knife::BmcsServerDelete.new }

  describe 'run server delete' do
    let(:config) do
      {
        compartment_id: 'compartmentA',
        bmcs_config_file: DUMMY_CONFIG_FILE,
        instance_id: 'ocid1.instance.oc1.test'
      }
    end

    let(:nil_response) do
      nil
    end

    let(:instance) do
      double(availability_domain: 'ad1',
             compartment_id: 'compartmentA',
             display_name: 'myname',
             id: 'ocid1.instance.oc1.test',
             image_id: 'myimage',
             region: 'phx',
             shape: 'round',
             subnet_id: 'supersubnet',
             lifecycle_state: 'RUNNING')
    end

    let(:terminated_instance) do
      double(availability_domain: 'ad1',
             compartment_id: 'compartmentA',
             display_name: 'myname',
             id: 'ocid1.instance.oc1.test',
             image_id: 'myimage',
             region: 'phx',
             shape: 'round',
             subnet_id: 'supersubnet',
             lifecycle_state: 'TERMINATED')
    end

    it 'should list missing required params' do
      expect(knife_bmcs_server_delete.ui).to receive(:error).with('Missing the following required parameters: instance-id')
      expect { knife_bmcs_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should delete remote instance' do
      knife_bmcs_server_delete.config = config

      allow(knife_bmcs_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_bmcs_server_delete.compute_client).to receive(:get_instance).and_return(instance)
      expect(knife_bmcs_server_delete.ui).to receive(:msg).with('Initiated delete of instance ocid1.instance.oc1.test')
      expect(knife_bmcs_server_delete.ui).not_to receive(:warn)

      knife_bmcs_server_delete.run
    end

    it 'wait options should reflect wait argument' do
      knife_bmcs_server_delete.config = config

      knife_bmcs_server_delete.config[:wait] = '-1'
      expect(knife_bmcs_server_delete.ui).to receive(:error).with('Wait value must be 0 or greater')
      expect { knife_bmcs_server_delete.run }.to raise_error(SystemExit)

      expect(knife_bmcs_server_delete.get_wait_options(0)).to eq(max_interval_seconds: 3)
      expect(knife_bmcs_server_delete.get_wait_options(1)).to eq(max_interval_seconds: 3, max_wait_seconds: 1)
    end

    it 'should fail if instance not accessible' do
      knife_bmcs_server_delete.config = config

      allow(knife_bmcs_server_delete.compute_client).to receive(:get_instance).and_raise(OracleBMC::Errors::ServiceError.new(200, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized'))
      expect(knife_bmcs_server_delete.compute_client).to_not receive(:terminate_instance)
      expect(knife_bmcs_server_delete.ui).to receive(:error).with('Instance not authorized or not found')
      expect { knife_bmcs_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should fail if instance already terminated' do
      knife_bmcs_server_delete.config = config

      allow(knife_bmcs_server_delete.compute_client).to receive(:get_instance).and_return(terminated_instance)
      expect(knife_bmcs_server_delete.compute_client).to_not receive(:terminate_instance)
      expect(knife_bmcs_server_delete.ui).to receive(:error).with('Instance is already in terminated state')
      expect { knife_bmcs_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should wait for instance to disappear' do
      knife_bmcs_server_delete.config = config
      knife_bmcs_server_delete.config[:wait] = '60'

      allow(knife_bmcs_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_bmcs_server_delete.compute_client).to receive(:get_instance).and_return(instance)
      expect(knife_bmcs_server_delete).to receive(:wait_for_instance_terminated)

      knife_bmcs_server_delete.run
    end

    it 'should not wait for instance to disappear if no wait' do
      knife_bmcs_server_delete.config = config
      knife_bmcs_server_delete.config[:wait] = nil

      allow(knife_bmcs_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_bmcs_server_delete.compute_client).to receive(:get_instance).and_return(instance)
      expect(knife_bmcs_server_delete).to_not receive(:wait_for_instance_terminated)

      knife_bmcs_server_delete.run
    end
  end
end

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'
require 'chef/knife/oci_server_delete'

Chef::Knife::OciServerDelete.load_deps

describe Chef::Knife::OciServerDelete do
  let(:knife_oci_server_delete) { Chef::Knife::OciServerDelete.new }

  describe 'run server delete' do
    let(:config) do
      {
        compartment_id: 'compartmentA',
        oci_config_file: DUMMY_CONFIG_FILE,
        instance_id: 'ocid1.instance.oc1.test',
        yes: true
      }
    end

    let(:nil_response) do
      nil
    end

    let(:get_server_ok_response) do
      double(data: instance,
             headers: {})
    end

    let(:get_server_terminated_response) do
      double(data: terminated_instance,
             headers: {})
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

    let(:chef_client) do
      double(name: 'myname')
    end

    let(:chef_node) do
      double(name: 'myname')
    end

    let(:chef_node_newname) do
      double(name: 'newname')
    end

    it 'should list missing required params' do
      expect(knife_oci_server_delete.ui).to receive(:error).with('Missing the following required parameters: instance-id')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should fail if node-name but not purge provided' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config[:chef_node_name] = 'test'
      knife_oci_server_delete.config.delete(:purge)

      expect(knife_oci_server_delete.ui).to receive(:error).with('--node-name requires --purge argument')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should delete remote instance and default named chef node' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config[:purge] = true

      allow(knife_oci_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      allow(Chef::Node).to receive(:load).with('myname').and_return(chef_node)
      allow(Chef::ApiClient).to receive(:load).with('myname').and_return(chef_client)
      expect(chef_node).to receive(:destroy)
      expect(chef_client).to receive(:destroy)
      expect(chef_client).to receive(:validator)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Chef node name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Initiated delete of instance ocid1.instance.oc1.test')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with("Deleted Chef node 'myname'")
      expect(knife_oci_server_delete.ui).not_to receive(:warn)

      knife_oci_server_delete.run
    end

    it 'should delete remote instance and specifically named chef node' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config[:purge] = true
      knife_oci_server_delete.config[:chef_node_name] = 'newname'

      allow(knife_oci_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      allow(Chef::Node).to receive(:load).with('newname').and_return(chef_node_newname)
      allow(Chef::ApiClient).to receive(:load).with('newname').and_return(chef_client)
      expect(chef_node_newname).to receive(:destroy)
      expect(chef_client).to receive(:destroy)
      expect(chef_client).to receive(:validator)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Chef node name: newname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Initiated delete of instance ocid1.instance.oc1.test')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with("Deleted Chef node 'newname'")
      expect(knife_oci_server_delete.ui).not_to receive(:warn)

      knife_oci_server_delete.run
    end

    it 'should delete remote instance' do
      knife_oci_server_delete.config = config

      allow(knife_oci_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Initiated delete of instance ocid1.instance.oc1.test')
      expect(knife_oci_server_delete.ui).not_to receive(:warn)

      knife_oci_server_delete.run
    end

    it 'wait options should reflect wait argument' do
      knife_oci_server_delete.config = config

      knife_oci_server_delete.config[:wait] = '-1'
      expect(knife_oci_server_delete.ui).to receive(:error).with('Wait value must be 0 or greater')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)

      expect(knife_oci_server_delete.get_wait_options(0)).to eq(max_interval_seconds: 3)
      expect(knife_oci_server_delete.get_wait_options(1)).to eq(max_interval_seconds: 3, max_wait_seconds: 1)
    end

    it 'should fail if instance not accessible' do
      knife_oci_server_delete.config = config

      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_raise(OCI::Errors::ServiceError.new(200, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized'))
      expect(knife_oci_server_delete.compute_client).to_not receive(:terminate_instance)
      expect(knife_oci_server_delete.ui).to receive(:error).with('Instance not authorized or not found')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should fail if instance already terminated' do
      knife_oci_server_delete.config = config

      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_terminated_response)
      expect(knife_oci_server_delete.compute_client).to_not receive(:terminate_instance)
      expect(knife_oci_server_delete.ui).to receive(:error).with('Instance is already in terminated state')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)
    end

    it 'should wait for instance to disappear' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config[:wait] = '60'

      allow(knife_oci_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      expect(knife_oci_server_delete).to receive(:wait_for_instance_terminated)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Initiated delete of instance ocid1.instance.oc1.test')

      knife_oci_server_delete.run
    end

    it 'should not wait for instance to disappear if no wait' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config[:wait] = nil

      allow(knife_oci_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      expect(knife_oci_server_delete).to_not receive(:wait_for_instance_terminated)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Initiated delete of instance ocid1.instance.oc1.test')

      knife_oci_server_delete.run
    end

    it 'negative delete confirmation should exit' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config.delete(:yes)

      allow(knife_oci_server_delete.ui).to receive(:ask).and_return('n').exactly(1).times
      expect(knife_oci_server_delete.compute_client).to_not receive(:terminate_instance)
      expect(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:ask).with('Delete server? (y/n)')
      expect(knife_oci_server_delete.ui).to receive(:error).with('Server delete canceled.')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)
    end

    it 'positive delete confirmation should proceed' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config.delete(:yes)

      allow(knife_oci_server_delete.ui).to receive(:ask).and_return('Y').exactly(1).times
      allow(knife_oci_server_delete.compute_client).to receive(:terminate_instance).and_return(nil_response)
      allow(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      expect(knife_oci_server_delete.ui).to receive(:ask).with('Delete server? (y/n)')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Initiated delete of instance ocid1.instance.oc1.test')
      expect(knife_oci_server_delete.ui).not_to receive(:warn)

      knife_oci_server_delete.run
    end

    it 'delete confirmation with invalid response should retry limited times' do
      knife_oci_server_delete.config = config
      knife_oci_server_delete.config.delete(:yes)

      allow(knife_oci_server_delete.ui).to receive(:ask).and_return('zn').exactly(3).times
      expect(knife_oci_server_delete.compute_client).to_not receive(:terminate_instance)
      expect(knife_oci_server_delete.compute_client).to receive(:get_instance).and_return(get_server_ok_response)
      expect(knife_oci_server_delete.ui).to receive(:msg).once.ordered.with('Instance name: myname')
      expect(knife_oci_server_delete.ui).to receive(:ask).with('Delete server? (y/n)')
      expect(knife_oci_server_delete.ui).to receive(:warn).with('Valid responses are ["yes", "no", "y", "n"]').exactly(3).times
      expect(knife_oci_server_delete.ui).to receive(:error).with('Server delete canceled.')
      expect { knife_oci_server_delete.run }.to raise_error(SystemExit)
    end
  end
end

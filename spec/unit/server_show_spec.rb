# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_show'
require 'oraclebmc'
require './spec/spec_helper'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'text' ? :msg : :output

  it "shows #{output_format} view" do
    knife_bmcs_server_show.config = config
    knife_bmcs_server_show.config[:format] = output_format

    allow(knife_bmcs_server_show.compute_client).to receive(:get_instance).and_return(response)
    allow(knife_bmcs_server_show.compute_client).to receive(:list_vnic_attachments).and_return(vnics)
    allow(knife_bmcs_server_show.network_client).to receive(:get_vnic).and_return(double(data: vnic_info))
    expect(knife_bmcs_server_show.ui).to receive(receive_type).at_least(7).times
    expect(knife_bmcs_server_show.ui).not_to receive(:warn)

    knife_bmcs_server_show.run
  end

  it "shows #{output_format} view with failed get_vnic request" do
    knife_bmcs_server_show.config = config
    knife_bmcs_server_show.config[:format] = output_format

    allow(knife_bmcs_server_show.compute_client).to receive(:get_instance).and_return(response)
    allow(knife_bmcs_server_show.compute_client).to receive(:list_vnic_attachments).and_return(vnics)
    allow(knife_bmcs_server_show.network_client).to receive(:get_vnic).and_raise(OracleBMC::Errors::ServiceError.new(404, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized'))
    expect(knife_bmcs_server_show.ui).to receive(receive_type).at_least(7).times
    expect(knife_bmcs_server_show.ui).not_to receive(:warn)

    knife_bmcs_server_show.run
  end

  it "shows #{output_format} with nil list" do
    knife_bmcs_server_show.config = config
    knife_bmcs_server_show.config[:format] = output_format

    allow(knife_bmcs_server_show.compute_client).to receive(:get_instance).and_return(nil_response)
    expect(knife_bmcs_server_show.ui).not_to receive(:warn)

    expect { knife_bmcs_server_show.run }.to raise_error(SystemExit)
  end
end

Chef::Knife::BmcsServerShow.load_deps

describe Chef::Knife::BmcsServerShow do
  let(:knife_bmcs_server_show) { Chef::Knife::BmcsServerShow.new }

  describe 'run server show' do
    let(:config) do
      {
        instance_id: 'ocid1.instance.oc1.test_server_show',
        compartment_id: 'compartmentA',
        bmcs_config_file: DUMMY_CONFIG_FILE,
        format: 'summary'
      }
    end

    let(:instance) do
      double(availability_domain: 'ad1',
             compartment_id: 'compartmentA',
             display_name: 'myname',
             id: '12345',
             image_id: 'myimage',
             lifecycle_state: 'RUNNING',
             region: 'regionA',
             shape: 'oblate-spheroid',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:response) do
      double(data: instance,
             headers: {})
    end

    let(:empty_response) do
      double(data: nil,
             headers: {})
    end

    let(:nil_response) do
      double(data: nil,
             headers: {})
    end

    let(:vnic) do
      double(instance_id: '12345',
             vnic_id: '34567',
             lifecycle_state: 'ATTACHED')
    end

    let(:vnics) do
      double(data: [vnic],
             headers: {})
    end

    let(:vnic_info) do
      double(:vnic_info,
             id: '34567',
             is_primary: true,
             private_ip: '10.0.0.1',
             public_ip: '129.213.29.14',
             hostname_label: 'mylabel',
             lifecycle_state: 'ATTACHED')
    end

    run_tests('text')
  end
end

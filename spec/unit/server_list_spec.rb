# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_list'
require 'oraclebmc'
require './spec/spec_helper'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'summary' ? :list : :output

  it "shows #{output_format} view" do
    knife_bmcs_server_list.config = config
    knife_bmcs_server_list.config[:format] = output_format

    allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(response)
    expect(knife_bmcs_server_list.ui).to receive(receive_type)
    expect(knife_bmcs_server_list.ui).not_to receive(:warn)

    knife_bmcs_server_list.run
  end

  it "shows #{output_format} with empty list" do
    knife_bmcs_server_list.config = config
    knife_bmcs_server_list.config[:format] = output_format

    allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(empty_response)
    expect(knife_bmcs_server_list.ui).to receive(receive_type)
    expect(knife_bmcs_server_list.ui).not_to receive(:warn)

    knife_bmcs_server_list.run
  end

  it "shows #{output_format} with nil list" do
    knife_bmcs_server_list.config = config
    knife_bmcs_server_list.config[:format] = output_format

    allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(nil_response)
    expect(knife_bmcs_server_list.ui).to receive(receive_type)
    expect(knife_bmcs_server_list.ui).not_to receive(:warn)

    knife_bmcs_server_list.run
  end

  it "warns #{output_format} when truncated" do
    knife_bmcs_server_list.config = config
    knife_bmcs_server_list.config[:format] = output_format
    response.headers['opc-next-page'] = 'page2'

    allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(response)
    expect(knife_bmcs_server_list.ui).to receive(receive_type)
    expect(knife_bmcs_server_list.ui).to receive(:warn).with('This list has been truncated. To view more items, increase the limit.')

    knife_bmcs_server_list.run
  end
end

describe Chef::Knife::BmcsServerList do
  let(:knife_bmcs_server_list) { Chef::Knife::BmcsServerList.new }

  describe 'run server list' do
    let(:config) do
      {
        compartment_id: 'compartmentA',
        bmcs_config_file: DUMMY_CONFIG_FILE,
        format: 'summary'
      }
    end

    let(:instance) do
      double(display_name: 'myname',
             id: '12345',
             lifecycle_state: 'RUNNING',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:response) do
      double(data: [instance],
             headers: {})
    end

    let(:empty_response) do
      double(data: [],
             headers: {})
    end

    let(:nil_response) do
      double(data: nil,
             headers: {})
    end

    run_tests('summary')
    run_tests('text')
  end
end

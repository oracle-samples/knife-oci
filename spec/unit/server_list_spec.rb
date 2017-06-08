# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_list'
require 'oraclebmc'
require './spec/spec_helper'

describe Chef::Knife::BmcsServerList do
  let(:knife_bmcs_server_list) { Chef::Knife::BmcsServerList.new }

  describe 'run server create' do
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
      double(data: [instance, instance],
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

    it 'shows summary view' do
      knife_bmcs_server_list.config = config

      allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(response)
      expect(knife_bmcs_server_list.ui).to receive(:list)
      expect(knife_bmcs_server_list.ui).not_to receive(:warn)

      knife_bmcs_server_list.run
    end

    it 'shows text view' do
      knife_bmcs_server_list.config = config
      knife_bmcs_server_list.config[:format] = 'text'

      allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(response)
      expect(knife_bmcs_server_list.ui).to receive(:output)
      expect(knife_bmcs_server_list.ui).not_to receive(:warn)

      knife_bmcs_server_list.run
    end

    it 'shows response with empty list' do
      knife_bmcs_server_list.config = config

      allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(empty_response)
      expect(knife_bmcs_server_list.ui).to receive(:list)
      expect(knife_bmcs_server_list.ui).not_to receive(:warn)

      knife_bmcs_server_list.run
    end

    it 'shows response with nil list' do
      knife_bmcs_server_list.config = config

      allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(nil_response)
      expect(knife_bmcs_server_list.ui).to receive(:list)
      expect(knife_bmcs_server_list.ui).not_to receive(:warn)

      knife_bmcs_server_list.run
    end

    it 'shows warning when truncated' do
      knife_bmcs_server_list.config = config
      response.headers['opc-next-page'] = 'page2'

      allow(knife_bmcs_server_list.compute_client).to receive(:list_instances).and_return(response)
      expect(knife_bmcs_server_list.ui).to receive(:list)
      expect(knife_bmcs_server_list.ui).to receive(:warn).with('This list has been truncated. To view more items, increase the limit.')

      knife_bmcs_server_list.run
    end
  end
end

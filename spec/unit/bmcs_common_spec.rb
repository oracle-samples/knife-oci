# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_list'
require 'chef/knife/bmcs_subnet_list'
require 'oraclebmc'
require './spec/spec_helper'

Chef::Knife::BmcsServerList.load_deps
Chef::Knife::BmcsSubnetList.load_deps

describe 'bmcs common utilities' do
  describe 'loading of config values' do
    let(:knife_bmcs_server_list) { Chef::Knife::BmcsServerList.new }
    it 'loads bmcs config from knife config' do
      knife_bmcs_server_list.config = { bmcs_config_file: DUMMY_CONFIG_FILE }
      expect(knife_bmcs_server_list.bmcs_config.tenancy).to eq('tenancy_for_default_profile')
    end

    it 'loads bmcs profile from knife config' do
      knife_bmcs_server_list.config = {
        bmcs_config_file: DUMMY_CONFIG_FILE,
        bmcs_profile: 'SECOND_PROFILE'
      }
      expect(knife_bmcs_server_list.bmcs_config.tenancy).to eq('tenancy_for_second_profile')
    end
  end

  describe 'config overrides' do
    let(:knife_bmcs_subnet_list) { Chef::Knife::BmcsSubnetList.new }

    let(:config) do
      {
        compartment_id: 'compartmentA',
        bmcs_config_file: DUMMY_CONFIG_FILE,
        vcn_id: 'ocid1.vcn.oc1..test'
      }
    end

    let(:empty_response) do
      double(data: [],
             headers: {})
    end

    it 'uses overridden region id' do
      knife_bmcs_subnet_list.config = config
      knife_bmcs_subnet_list.config[:region] = 'overridden-region'

      allow(knife_bmcs_subnet_list.network_client).to receive(:list_subnets).and_return(empty_response)
      expect(knife_bmcs_subnet_list.ui).not_to receive(:warn)
      expect(knife_bmcs_subnet_list.bmcs_config.region).to eq('overridden-region')
      expect(knife_bmcs_subnet_list.compute_client.region).to eq('overridden-region')

      knife_bmcs_subnet_list.run
    end
  end
end

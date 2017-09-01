# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'

describe 'oci common utilities' do
  describe 'loading of config values' do
    let(:knife_oci_server_list) { Chef::Knife::OciServerList.new }
    it 'loads oci config from knife config' do
      knife_oci_server_list.config = { oci_config_file: DUMMY_CONFIG_FILE }
      expect(knife_oci_server_list.oci_config.tenancy).to eq('tenancy_for_default_profile')
    end

    it 'loads oci profile from knife config' do
      knife_oci_server_list.config = {
        oci_config_file: DUMMY_CONFIG_FILE,
        oci_profile: 'SECOND_PROFILE'
      }
      expect(knife_oci_server_list.oci_config.tenancy).to eq('tenancy_for_second_profile')
    end
  end

  describe 'config overrides' do
    let(:knife_oci_subnet_list) { Chef::Knife::OciSubnetList.new }

    let(:config) do
      {
        compartment_id: 'compartmentA',
        oci_config_file: DUMMY_CONFIG_FILE,
        vcn_id: 'ocid1.vcn.oc1..test'
      }
    end

    let(:empty_response) do
      double(data: [],
             headers: {})
    end

    it 'uses overridden region id' do
      knife_oci_subnet_list.config = config
      knife_oci_subnet_list.config[:region] = 'overridden-region'

      allow(knife_oci_subnet_list.network_client).to receive(:list_subnets).and_return(empty_response)
      expect(knife_oci_subnet_list.ui).not_to receive(:warn)
      expect(knife_oci_subnet_list.ui).to receive(:output)
      expect(knife_oci_subnet_list.oci_config.region).to eq('overridden-region')
      expect(knife_oci_subnet_list.compute_client.region).to eq('overridden-region')

      knife_oci_subnet_list.run
    end
  end
end

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'
require 'chef/knife/oci_subnet_list'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'summary' ? :list : :output

  it 'missing parameters should exit with error' do
    expect(knife_oci_subnet_list.ui).to receive(:error).with('Missing the following required parameters: vcn-id')
    expect { knife_oci_subnet_list.run }.to raise_error(SystemExit)
  end

  it "shows #{output_format} view" do
    knife_oci_subnet_list.config = config
    knife_oci_subnet_list.config[:format] = output_format

    allow(knife_oci_subnet_list.network_client).to receive(:list_subnets).and_return(multi_response)
    expect(knife_oci_subnet_list.ui).to receive(receive_type)
    expect(knife_oci_subnet_list.ui).not_to receive(:warn)

    knife_oci_subnet_list.run
  end

  it "shows #{output_format} with nil list" do
    knife_oci_subnet_list.config = config
    knife_oci_subnet_list.config[:format] = output_format

    allow(knife_oci_subnet_list.network_client).to receive(:list_subnets).and_return(nil_response)
    expect(knife_oci_subnet_list.ui).to receive(receive_type)
    expect(knife_oci_subnet_list.ui).not_to receive(:warn)

    knife_oci_subnet_list.run
  end

  it "shows #{output_format} with empty list" do
    knife_oci_subnet_list.config = config
    knife_oci_subnet_list.config[:format] = output_format

    allow(knife_oci_subnet_list.network_client).to receive(:list_subnets).and_return(empty_response)
    expect(knife_oci_subnet_list.ui).to receive(receive_type)
    expect(knife_oci_subnet_list.ui).not_to receive(:warn)

    knife_oci_subnet_list.run
  end

  it "shows warning #{output_format} when truncated" do
    knife_oci_subnet_list.config = config
    knife_oci_subnet_list.config[:format] = output_format
    knife_oci_subnet_list.config[:limit] = 1
    response = multi_response
    response.headers['opc-next-page'] = 'page2'

    allow(knife_oci_subnet_list.network_client).to receive(:list_subnets).and_return(response, empty_response)
    expect(knife_oci_subnet_list.ui).to receive(receive_type)
    expect(knife_oci_subnet_list.ui).to receive(:warn).with('This list has been truncated. To view more items, increase the limit.')

    knife_oci_subnet_list.run
  end
end

Chef::Knife::OciSubnetList.load_deps

describe Chef::Knife::OciSubnetList do
  let(:knife_oci_subnet_list) { Chef::Knife::OciSubnetList.new }

  describe 'list subnet' do
    let(:config) do
      {
        compartment_id: 'compartmentA',
        oci_config_file: DUMMY_CONFIG_FILE,
        vcn_id: 'ocid1.vcn.oc1..test'
      }
    end

    let(:subnet) do
      double(compartmentId: 'ocid1.tenancy.oc1..test',
             id: 'ocid1.subnet.oc1..test',
             display_name: 'subnet_1',
             cidr_block: '10.0.0.0/24',
             availability_domain: 'test-ad',
             lifecycle_state: 'ACTIVE',
             to_hash: { 'display_name' => 'hash_value' })
    end

    let(:multi_response) do
      double(data: [subnet, subnet],
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

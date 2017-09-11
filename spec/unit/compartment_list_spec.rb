# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'
require 'chef/knife/oci_compartment_list'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'summary' ? :list : :output

  it "compartment shows #{output_format} view" do
    knife_oci_compartment_list.config = config
    knife_oci_compartment_list.config[:format] = output_format

    allow(knife_oci_compartment_list.identity_client).to receive(:list_compartments).and_return(multi_response, empty_response)
    expect(knife_oci_compartment_list.ui).to receive(receive_type)
    expect(knife_oci_compartment_list.ui).not_to receive(:warn)

    knife_oci_compartment_list.run
  end

  it "use tenancy not compartment id #{output_format}" do
    knife_oci_compartment_list.config = config
    knife_oci_compartment_list.config[:format] = output_format

    allow(knife_oci_compartment_list.identity_client).to receive(:list_compartments).and_return(multi_response, empty_response)
    expect(knife_oci_compartment_list).not_to receive(:compartment_id)
    expect(knife_oci_compartment_list.oci_config).to receive(:tenancy).twice
    expect(knife_oci_compartment_list.ui).to receive(receive_type)
    expect(knife_oci_compartment_list.ui).not_to receive(:warn)

    knife_oci_compartment_list.run
  end

  it "compartment shows #{output_format} with nil list" do
    knife_oci_compartment_list.config = config
    knife_oci_compartment_list.config[:format] = output_format

    allow(knife_oci_compartment_list.identity_client).to receive(:list_compartments).and_return(nil_response)
    expect(knife_oci_compartment_list.ui).to receive(receive_type)
    expect(knife_oci_compartment_list.ui).not_to receive(:warn)

    knife_oci_compartment_list.run
  end

  it "shows response #{output_format} with empty list" do
    knife_oci_compartment_list.config = config
    knife_oci_compartment_list.config[:format] = output_format

    allow(knife_oci_compartment_list.identity_client).to receive(:list_compartments).and_return(empty_response)
    expect(knife_oci_compartment_list.ui).to receive(receive_type)
    expect(knife_oci_compartment_list.ui).not_to receive(:warn)

    knife_oci_compartment_list.run
  end

  it "shows warning #{output_format} when truncated" do
    knife_oci_compartment_list.config = config
    knife_oci_compartment_list.config[:format] = output_format
    knife_oci_compartment_list.config[:limit] = 1
    response = multi_response
    response.headers['opc-next-page'] = 'page2'

    allow(knife_oci_compartment_list.identity_client).to receive(:list_compartments).and_return(response, empty_response)
    expect(knife_oci_compartment_list.ui).to receive(receive_type)
    expect(knife_oci_compartment_list.ui).to receive(:warn).with('This list has been truncated. To view more items, increase the limit.')

    knife_oci_compartment_list.run
  end

  it "does not show warning #{output_format} when next page is empty" do
    knife_oci_compartment_list.config = config
    knife_oci_compartment_list.config[:format] = output_format
    response = multi_response
    response.headers['opc-next-page'] = 'page2'

    allow(knife_oci_compartment_list.identity_client).to receive(:list_compartments).and_return(response, empty_response)
    expect(knife_oci_compartment_list.ui).to receive(receive_type)
    expect(knife_oci_compartment_list.ui).to_not receive(:warn)

    knife_oci_compartment_list.run
  end
end

Chef::Knife::OciCompartmentList.load_deps

describe Chef::Knife::OciCompartmentList do
  let(:knife_oci_compartment_list) { Chef::Knife::OciCompartmentList.new }

  describe 'list compartment' do
    let(:config) do
      {
        oci_config_file: DUMMY_CONFIG_FILE,
        format: 'summary'
      }
    end

    let(:compartment) do
      double(compartmentId: 'ocid1.tenancy.oc1..test',
             id: '12345',
             name: 'Chef',
             description: 'Chef Test Compartment',
             lifecycleState: 'ACTIVE',
             to_hash: { 'display_name' => 'hash_name' })
    end

    let(:multi_response) do
      double(data: [compartment, compartment],
             headers: { 'opc-next-page' => 'aaaaaaaaaaaaaaaa' })
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

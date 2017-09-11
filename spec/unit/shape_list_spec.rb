# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'
require 'chef/knife/oci_shape_list'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'summary' ? :list : :output

  it "shows #{output_format} view" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:list_shapes).and_return(response)
    expect(knife_oci_server_show.ui).to receive(receive_type)
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    knife_oci_server_show.run
  end

  it "shows #{output_format} with empty list" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:list_shapes).and_return(empty_response)
    expect(knife_oci_server_show.ui).to receive(receive_type)
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    knife_oci_server_show.run
  end

  it "shows #{output_format} with nil list" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:list_shapes).and_return(nil_response)
    expect(knife_oci_server_show.ui).to receive(receive_type)
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    knife_oci_server_show.run
  end

  it "warns #{output_format} when truncated" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format
    knife_oci_server_show.config[:limit] = 1
    response.headers['opc-next-page'] = 'page2'

    allow(knife_oci_server_show.compute_client).to receive(:list_shapes).and_return(response, empty_response)
    expect(knife_oci_server_show.ui).to receive(receive_type)
    expect(knife_oci_server_show.ui).to receive(:warn).with('This list has been truncated. To view more items, increase the limit.')

    knife_oci_server_show.run
  end
end

Chef::Knife::OciShapeList.load_deps

describe Chef::Knife::OciShapeList do
  let(:knife_oci_server_show) { Chef::Knife::OciShapeList.new }

  describe 'run shape list' do
    let(:config) do
      {
        compartment_id: 'compartmentA',
        oci_config_file: DUMMY_CONFIG_FILE,
        format: 'summary'
      }
    end

    let(:shape1) do
      double(shape: 'BM.Standard1.36',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:shape2) do
      double(shape: 'VM.Standard1.2',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:shape3) do
      double(shape: 'VM.Standard1.8',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:shape4) do
      double(shape: 'VM.DenseIO1.4',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:response) do
      double(data: [shape1, shape2, shape3, shape4],
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

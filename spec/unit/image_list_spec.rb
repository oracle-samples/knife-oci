# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'
require 'chef/knife/bmcs_image_list'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'summary' ? :list : :output

  it "shows #{output_format} view" do
    knife_bmcs_image_list.config = config
    knife_bmcs_image_list.config[:format] = output_format

    allow(knife_bmcs_image_list.compute_client).to receive(:list_images).and_return(response)
    expect(knife_bmcs_image_list.ui).to receive(receive_type)
    expect(knife_bmcs_image_list.ui).not_to receive(:warn)

    knife_bmcs_image_list.run
  end

  it "shows #{output_format} with empty list" do
    knife_bmcs_image_list.config = config
    knife_bmcs_image_list.config[:format] = output_format

    allow(knife_bmcs_image_list.compute_client).to receive(:list_images).and_return(empty_response)
    expect(knife_bmcs_image_list.ui).to receive(receive_type)
    expect(knife_bmcs_image_list.ui).not_to receive(:warn)

    knife_bmcs_image_list.run
  end

  it "shows #{output_format} with nil list" do
    knife_bmcs_image_list.config = config
    knife_bmcs_image_list.config[:format] = output_format

    allow(knife_bmcs_image_list.compute_client).to receive(:list_images).and_return(nil_response)
    expect(knife_bmcs_image_list.ui).to receive(receive_type)
    expect(knife_bmcs_image_list.ui).not_to receive(:warn)

    knife_bmcs_image_list.run
  end

  it "warns #{output_format} when truncated" do
    knife_bmcs_image_list.config = config
    knife_bmcs_image_list.config[:format] = output_format
    knife_bmcs_image_list.config[:limit] = 1
    response.headers['opc-next-page'] = 'page2'

    allow(knife_bmcs_image_list.compute_client).to receive(:list_images).and_return(response, empty_response)
    expect(knife_bmcs_image_list.ui).to receive(receive_type)
    expect(knife_bmcs_image_list.ui).to receive(:warn).with('This list has been truncated. To view more items, increase the limit.')

    knife_bmcs_image_list.run
  end
end

Chef::Knife::BmcsImageList.load_deps

describe Chef::Knife::BmcsImageList do
  let(:knife_bmcs_image_list) { Chef::Knife::BmcsImageList.new }

  describe 'run shape list' do
    let(:config) do
      {
        compartment_id: 'compartmentA',
        bmcs_config_file: DUMMY_CONFIG_FILE,
        format: 'summary'
      }
    end

    let(:image1) do
      double(id: 'ocid1.image.oc1.DUMMY.1',
             lifecycle_state: 'AVAILABLE',
             operating_system: 'Windows',
             operating_system_version: 'Server 2012 R2 Standard',
             display_name: 'Windows-Server-2012-R2-Standard-Edition-BM-2017.07.25-0',
             create_image_allowed: true,
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:image2) do
      double(id: 'ocid1.image.oc1.DUMMY.2',
             lifecycle_state: 'AVAILABLE',
             operating_system: 'Oracle Linux',
             operating_system_version: '7.3',
             display_name: 'Oracle-Linux-7.3-2017.07.17-0',
             create_image_allowed: true,
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:image3) do
      double(id: 'ocid1.image.oc1.DUMMY.3',
             lifecycle_state: 'AVAILABLE',
             operating_system: 'CentOS',
             operating_system_version: '7',
             display_name: 'CentOS-7-2017.07.17-0',
             create_image_allowed: true,
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:image4) do
      double(id: 'ocid1.image.oc1.DUMMY.4',
             lifecycle_state: 'DISABLED',
             operating_system: 'Multics',
             operating_system_version: '12.6f',
             display_name: 'Multics-12.6f-(Y2K fixes)',
             create_image_allowed: false,
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:response) do
      double(data: [image1, image2, image3, image4],
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

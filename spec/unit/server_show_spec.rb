# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require './spec/spec_helper'
require 'json'
require 'date'
require 'chef/knife/oci_server_show'

# rubocop:disable Metrics/AbcSize
def run_tests(output_format)
  receive_type = output_format == 'text' ? :msg : :output

  it "shows #{output_format} view" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:get_instance).and_return(response)
    allow(knife_oci_server_show.compute_client).to receive(:list_vnic_attachments).and_return(vnics)
    allow(knife_oci_server_show.network_client).to receive(:get_vnic).and_return(double(data: vnic_info1), double(data: vnic_info2))
    allow(knife_oci_server_show.network_client).to receive(:get_subnet).and_return(double(data: subnet1))
    allow(knife_oci_server_show.identity_client).to receive(:get_compartment).and_return(double(data: compartmentA))
    allow(knife_oci_server_show.compute_client).to receive(:get_image).and_return(double(data: image1))
    allow(knife_oci_server_show.network_client).to receive(:get_vcn).and_return(double(data: vcn1))
    expect(knife_oci_server_show.ui).to receive(receive_type).at_least(7).times
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    knife_oci_server_show.run
  end

  it "shows #{output_format} view with failed get_vnic request" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:get_instance).and_return(response)
    allow(knife_oci_server_show.compute_client).to receive(:list_vnic_attachments).and_return(vnics)
    allow(knife_oci_server_show.network_client).to receive(:get_vnic).and_raise(
      OCI::Errors::ServiceError.new(404, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized')
    )
    allow(knife_oci_server_show.network_client).to receive(:get_subnet).and_return(double(data: subnet1))
    allow(knife_oci_server_show.identity_client).to receive(:get_compartment).and_return(double(data: compartmentA))
    allow(knife_oci_server_show.compute_client).to receive(:get_image).and_return(double(data: image1))
    allow(knife_oci_server_show.network_client).to receive(:get_vcn).and_return(double(data: vcn1))
    expect(knife_oci_server_show.ui).to receive(receive_type).at_least(7).times
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    knife_oci_server_show.run
  end

  it "shows #{output_format} view with many failed requests" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:get_instance).and_return(response)
    allow(knife_oci_server_show.compute_client).to receive(:list_vnic_attachments).and_return(vnics)
    allow(knife_oci_server_show.network_client).to receive(:get_vnic).and_return(double(data: vnic_info1))
    allow(knife_oci_server_show.network_client).to receive(:get_subnet).and_raise(
      OCI::Errors::ServiceError.new(404, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized')
    )
    allow(knife_oci_server_show.identity_client).to receive(:get_compartment).and_raise(
      OCI::Errors::ServiceError.new(404, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized')
    )
    allow(knife_oci_server_show.compute_client).to receive(:get_image).and_raise(
      OCI::Errors::ServiceError.new(404, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized')
    )
    allow(knife_oci_server_show.network_client).to receive(:get_vcn).and_raise(
      OCI::Errors::ServiceError.new(404, 'NotAuthorizedOrNotFound', 'test_request_id', 'Not authorized')
    )
    expect(knife_oci_server_show.ui).to receive(receive_type).at_least(7).times
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    knife_oci_server_show.run
  end

  it "shows #{output_format} with nil list" do
    knife_oci_server_show.config = config
    knife_oci_server_show.config[:format] = output_format

    allow(knife_oci_server_show.compute_client).to receive(:get_instance).and_return(nil_response)
    expect(knife_oci_server_show.ui).not_to receive(:warn)

    expect { knife_oci_server_show.run }.to raise_error(SystemExit)
  end
end

Chef::Knife::OciServerShow.load_deps

describe Chef::Knife::OciServerShow do
  let(:knife_oci_server_show) { Chef::Knife::OciServerShow.new }

  describe 'run server show' do
    let(:compartmentA) do
      double(:compartmentA,
             description: 'myname',
             id: 'compartmentA',
             name: 'compartmentA name',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:config) do
      {
        instance_id: 'ocid1.instance.oc1.test_server_show',
        compartment_id: 'compartmentA',
        oci_config_file: DUMMY_CONFIG_FILE,
        format: 'summary'
      }
    end

    let(:image1) do
      double(:image1,
             display_name: 'myimage-name-1',
             id: 'myimage-1',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:instance) do
      double(:instance,
             availability_domain: 'ad1',
             compartment_id: 'compartmentA',
             display_name: 'myname',
             id: '12345',
             image_id: 'myimage-1',
             lifecycle_state: 'RUNNING',
             region: 'regionA',
             shape: 'oblate-spheroid',
             time_created: DateTime.new(2017, 7, 16, 12, 13, 14),
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:response) do
      double(data: instance,
             headers: {})
    end

    let(:nil_response) do
      double(data: nil,
             headers: {})
    end

    let(:subnet1) do
      double(:subnet1,
             id: 'mysubnet-1',
             display_name: 'compartmentA test subnet mysubnet-1',
             subnet_domain_name: 'mysubnet-1.mycvn1.oraclevcn.com',
             vcn_id: 'myvcn1',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:vcn1) do
      double(:vcn1,
             compartment_id: 'compartmentA',
             display_name: 'myvcn-1 display name',
             id: 'myvcn1',
             to_hash: { 'display_name' => 'hashname' })
    end

    let(:vnic1) do
      double(:vnic1,
             instance_id: '12345',
             vnic_id: '34567',
             lifecycle_state: 'ATTACHED')
    end

    let(:vnic2) do
      double(:vnic2,
             instance_id: '12346',
             vnic_id: '34568',
             lifecycle_state: 'ATTACHED')
    end

    let(:vnics) do
      double(data: [vnic1, vnic2],
             headers: {})
    end

    let(:vnic_info1) do
      double(:vnic_info1,
             hostname_label: 'mylabel',
             id: '34567',
             is_primary: true,
             private_ip: '10.0.0.1',
             public_ip: '129.213.29.14',
             subnet_id: 'mysubnet-1',
             lifecycle_state: 'ATTACHED')
    end

    let(:vnic_info2) do
      double(:vnic_info2,
             hostname_label: 'mylabel-vnic-2',
             id: '34568',
             is_primary: false,
             private_ip: '10.0.0.2',
             public_ip: '129.213.29.15',
             subnet_id: 'mysubnet-1',
             lifecycle_state: 'ATTACHED')
    end

    run_tests('text')
  end
end

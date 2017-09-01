# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/oci_common_options'
require 'chef/knife/oci_helper'

# Methods to extend the instance model
module ServerDetails
  attr_accessor :compartment_name
  attr_accessor :image_name
  attr_accessor :launchtime
  attr_accessor :vcn_id
  attr_accessor :vcn_name
end

# Methods to extend the vnic model
module VnicDetails
  attr_accessor :fqdn
  attr_accessor :subnet_name
  attr_accessor :vcn_id
end

class Chef
  class Knife
    # List OCI instances. Note that this lists all instances in a
    # compartment, not just those that are set up as Chef nodes.
    class OciServerShow < Knife
      banner 'knife oci server show (options)'

      include OciHelper
      include OciCommonOptions

      deps do
        require 'oci'
      end

      option :instance_id,
             long: '--instance_id LIMIT',
             description: 'The OCID of the server to display. (required)'

      def lookup_compartment_name(compartment_id)
        compartment = identity_client.get_compartment(compartment_id, {})
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
      else
        compartment.data.name
      end

      def lookup_image_name(image_id)
        image = compute_client.get_image(image_id, {})
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
      else
        image.data.display_name
      end

      def lookup_vcn_name(vcn_id)
        vcn = network_client.get_vcn(vcn_id, {})
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
      else
        vcn.data.display_name
      end

      def add_server_details(server, vcn_id)
        server.extend ServerDetails

        server.launchtime = server.time_created.strftime('%a, %e %b %Y %T %Z')
        server.compartment_name = lookup_compartment_name(server.compartment_id)
        server.image_name = lookup_image_name(server.image_id)
        server.vcn_id = vcn_id
        server.vcn_name = lookup_vcn_name(vcn_id)
      end

      def add_vnic_details(vnic)
        vnic.extend VnicDetails

        begin
          subnet = network_client.get_subnet(vnic.subnet_id, {})
        rescue OCI::Errors::ServiceError => service_error
          raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
        else
          vnic.fqdn = vnic.hostname_label + '.' + subnet.data.subnet_domain_name if
            subnet.data && subnet.data.subnet_domain_name && vnic.hostname_label
          vnic.subnet_name = subnet.data.display_name if
            subnet.data && subnet.data.display_name
          # piggyback the vcn_id from here, so we can avoid a few network calls
          vnic.vcn_id = subnet.data.vcn_id
        end
      end

      def run
        validate_required_params(%i[instance_id], config)
        vnic_array = []
        server = check_can_access_instance(config[:instance_id])
        error_and_exit 'Unable to retrieve instance' unless server.data
        vnics = compute_client.list_vnic_attachments(compartment_id, instance_id: config[:instance_id])
        vnics.data && vnics.data.each do |vnic|
          next unless vnic.lifecycle_state == 'ATTACHED'
          begin
            vnic_info = network_client.get_vnic(vnic.vnic_id, {})
          rescue OCI::Errors::ServiceError => service_error
            raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
          else
            add_vnic_details(vnic_info.data)
            # for now, only display information for primary vnic
            if vnic_info.data.is_primary == true
              vnic_array.push(vnic_info.data)
              break
            end
          end
        end
        add_server_details(server.data, vnic_array[0] ? vnic_array[0].vcn_id : nil)

        display_server_info(config, server.data, vnic_array)
      end
    end
  end
end

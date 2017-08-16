# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

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
end

class Chef
  class Knife
    # List BMCS instances. Note that this lists all instances in a
    # compartment, not just those that are set up as Chef nodes.
    class BmcsServerShow < Knife
      banner 'knife bmcs server show (options)'

      include BmcsHelper
      include BmcsCommonOptions

      deps do
        require 'oraclebmc'
      end

      option :instance_id,
             long: '--instance_id LIMIT',
             description: 'The OCID of the server to display. (required)'

      def add_server_details(server)
        server.extend ServerDetails

        server.compartment_name = 'server compartment name'
        server.image_name = 'server image name'
        server.launchtime = 'server launchtime'
        server.vcn_id = 'server vnc id'
        server.vcn_name = 'server vcn name'
      end

      def add_vnic_details(vnic)
        vnic.extend VnicDetails

        vnic.fqdn = 'vnic fqdn'
        vnic.subnet_name = 'vnic subnet name'
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
            add_vnic_details(vnic_info.data)
          rescue OracleBMC::Errors::ServiceError => service_error
            raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
          else
            # for now, only display information for primary vnic
            if vnic_info.data.is_primary == true
              vnic_array.push(vnic_info.data)
              break
            end
          end
        end
        add_server_details(server.data)

        display_server_info(config, server.data, vnic_array)
      end
    end
  end
end

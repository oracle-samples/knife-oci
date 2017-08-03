# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

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
             description: 'The OCID of the server to display.'

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

        display_server_info(config, server.data, vnic_array)
      end
    end
  end
end

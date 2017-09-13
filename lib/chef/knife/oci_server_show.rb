# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/oci_common_options'
require 'chef/knife/oci_helper'
require 'chef/knife/oci_helper_show'

class Chef
  class Knife
    # List details of a particular OCI instance.
    class OciServerShow < Knife
      banner 'knife oci server show (options)'

      include OciHelper
      include OciHelperShow
      include OciCommonOptions

      deps do
        require 'oci'
      end

      option :instance_id,
             long: '--instance_id INSTANCE',
             description: 'The OCID of the server to display. (required)'

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
            raise unless service_error.service_code == 'NotAuthorizedOrNotFound'
          else
            add_vnic_details(vnic_info.data)
            if vnic_info.data.is_primary == true
              vnic_array.unshift(vnic_info.data) # make primary interface first in the array
            else
              vnic_array.push(vnic_info.data)
            end
          end
        end
        add_server_details(server.data, vnic_array[0] ? vnic_array[0].vcn_id : nil)

        display_server_info(config, server.data, vnic_array)
      end
    end
  end
end

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
        require 'pp'
      end

      option :instance_id,
             long: '--instance_id LIMIT',
             description: 'The OCID of the server to display.'

      def check_can_access_instance(instance_id)
        response = compute_client.get_instance(instance_id)
      rescue OracleBMC::Errors::ServiceError => service_error
        raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
        error_and_exit 'Instance not authorized or not found'
      else
        return response
      end

      # Holds information needed to display vnic information
      class VnicInfo
        def initialize(private_ip, public_ip, hostname_label)
          @private_ip = private_ip
          @public_ip = public_ip
          @hostname_label = hostname_label
        end

        attr_reader :private_ip

        attr_reader :public_ip

        attr_reader :hostname_label
      end

      def run
        validate_required_params(%i[instance_id], config)

        vnic_array = []

        server = check_can_access_instance(config[:instance_id])

        vnics = compute_client.list_vnic_attachments(compartment_id, instance_id: config[:instance_id])
        vnics.data.each do |vnic|
          if vnic.lifecycle_state == 'ATTACHED'
            begin
              vnic_info = network_client.get_vnic(vnic.vnic_id, {})
            rescue OracleBMC::Errors::ServiceError
              private_ip = ''
              public_ip = ''
              hostname_label = ''
            else
              private_ip = vnic_info.data.private_ip
              public_ip = vnic_info.data.public_ip || ''
              hostname_label = vnic_info.data.hostname_label || ''
            end
          else
            private_ip = ''
            public_ip = ''
            hostname_label = ''
          end
          if private_ip != ''
            vnic_array.push(VnicInfo.new(private_ip, public_ip, hostname_label))
          end
        end

        pp 'vnic_array: [', vnic_array, ']'

        display_server_info(config, server.data, vnic_array)
      end
    end
  end
end

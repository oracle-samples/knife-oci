# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List BMCS instances. Note that this lists all instances in a
    # compartment, not just those that are set up as Chef nodes.
    class BmcsServerList < Knife
      banner 'knife bmcs server list (options)'

      include BmcsHelper
      include BmcsCommonOptions

      deps do
        require 'oraclebmc'
      end

      option :limit,
             long: '--limit LIMIT',
             description: 'The maximum number of items to return.'

      def run
        options = {}
        options[:limit] = config[:limit] if config[:limit]

        servers = {}

        response = compute_client.list_instances(compartment_id, options)

        if config[:format] == 'summary' && response.data
          # build a hash of hashs, keyed off of server_id
          response.data.each do |server|
            vnics = compute_client.list_vnic_attachments(compartment_id, instance_id: server.id)
            vnics.data.each do |vnic|
              servers[vnic.instance_id] = {}
              servers[vnic.instance_id]['vnic_id'] = vnic.vnic_id
              if vnic.lifecycle_state == 'ATTACHED'
                begin
                  vnic_info = network_client.get_vnic(vnic.vnic_id, {})
                rescue OracleBMC::Errors::ServiceError
                  servers[vnic.instance_id]['private_ip'] = ''
                  servers[vnic.instance_id]['public_ip'] = ''
                else
                  servers[vnic.instance_id]['private_ip'] = vnic_info.data.private_ip
                  servers[vnic.instance_id]['public_ip'] = vnic_info.data.public_ip || ''
                  break
                end
              else
                servers[vnic.instance_id]['private_ip'] = ''
                servers[vnic.instance_id]['public_ip'] = ''
              end
            end
          end
        end

        display_list(response,
                     ['Display Name', 'State', 'Public IP', 'Private IP', 'ID']) do |item|
          [item.display_name,
           item.lifecycle_state,
           servers[item.id]['public_ip'],
           servers[item.id]['private_ip'],
           item.id]
        end
      end
    end
  end
end

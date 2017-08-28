# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List BMCS subnets in a VCN.
    class BmcsSubnetList < Knife
      banner 'knife bmcs subnet list (options)'

      include BmcsHelper
      include BmcsCommonOptions

      deps do
        require 'oraclebmc'
      end

      option :limit,
             long: '--limit LIMIT',
             description: 'The maximum number of items to return.'

      option :vcn_id,
             long: '--vcn-id VCN',
             description: 'The VCN ID to list subnets for. (required)'

      def run
        validate_required_params(%i[vcn_id], config)
        options = {}
        options[:limit] = config[:limit] if config[:limit]

        columns = ['Display Name', 'ID', 'CIDR Block', 'Availability Domain', 'State']

        list_for_display, last_response = get_display_results(options) do |client_options, first_row|
          response = network_client.list_subnets(compartment_id, config[:vcn_id], client_options)

          items = response_to_list(response, columns, include_headings: first_row) do |item|
            [item.display_name, item.id, item.cidr_block, item.availability_domain, item.lifecycle_state]
          end
          [response, items]
        end

        display_list_from_array(list_for_display, columns.length)
        warn_if_page_is_truncated(last_response)
      end
    end
  end
end

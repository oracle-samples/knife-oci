# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/oci_common_options'
require 'chef/knife/oci_helper'

class Chef
  class Knife
    # List OCI VCNs. Note that this lists all VCNs in a compartment, not just those that are set up as Chef nodes.
    class OciVcnList < Knife
      banner 'knife oci vcn list (options)'

      include OciHelper
      include OciCommonOptions

      deps do
        require 'oci'
      end

      option :limit,
             long: '--limit LIMIT',
             description: 'The maximum number of items to return.'

      def run
        options = {}
        options[:limit] = config[:limit] if config[:limit]

        columns = ['Display Name', 'ID', 'CIDR Block', 'State']

        list_for_display = config[:format] == 'summary' ? bold(columns) : []
        list_data, last_response = get_display_results(options) do |client_options|
          response = network_client.list_vcns(compartment_id, client_options)

          items = response_to_list(response) do |item|
            [item.display_name, item.id, item.cidr_block, item.lifecycle_state]
          end
          [response, items]
        end
        list_for_display += list_data

        display_list_from_array(list_for_display, columns.length)
        warn_if_page_is_truncated(last_response)
      end
    end
  end
end

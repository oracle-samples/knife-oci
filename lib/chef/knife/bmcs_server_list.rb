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

        columns = ['Display Name', 'State', 'ID']

        list_for_display, last_response = get_display_results(options) do |client_options, first_row|
          response = compute_client.list_instances(compartment_id, client_options)

          items = response_to_list(response, columns, include_headings: first_row) do |item|
            [item.display_name,
             item.lifecycle_state,
             item.id]
          end
          [response, items]
        end

        display_list_from_array(list_for_display, columns.length)
        warn_if_page_is_truncated(last_response)
      end
    end
  end
end

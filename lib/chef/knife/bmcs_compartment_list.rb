# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List BMCS compartments
    class BmcsCompartmentList < Knife
      banner 'knife bmcs compartment list (options)'

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

        response = identity_client.list_compartments(compartment_id, options)
        # Check whether there is a next page to decide whether to show an 'output is truncated' warning.
        # TODO: expected to be addressed server-side in a future release at which point this special
        # handling can be removed.
        show_truncated_warning = false
        if response && response.headers.include?('opc-next-page')
          response_page2 = identity_client.list_compartments(compartment_id, options.merge(page: response.headers['opc-next-page']))
          show_truncated_warning = response_page2 && response_page2.data && !response_page2.data.empty?
        end

        display_list(response, ['Display Name', 'ID'], warn_on_truncated: show_truncated_warning) do |item|
          [item.name, item.id]
        end
      end
    end
  end
end

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/oci_common_options'
require 'chef/knife/oci_helper'

class Chef
  class Knife
    # List OCI compartments
    class OciCompartmentList < Knife
      banner 'knife oci compartment list (options)'

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

        columns = ['Display Name', 'ID']

        list_for_display = config[:format] == 'summary' ? bold(columns) : []
        list_data, last_response = get_display_results(options) do |client_options|
          response = identity_client.list_compartments(oci_config.tenancy, client_options)

          items = response_to_list(response) do |item|
            [item.name, item.id]
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

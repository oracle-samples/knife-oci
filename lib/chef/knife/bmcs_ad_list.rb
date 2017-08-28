# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List availability domains
    class BmcsAdList < Knife
      banner 'knife bmcs ad list (options)'

      include BmcsHelper
      include BmcsCommonOptions

      deps do
        require 'oraclebmc'
      end

      def run
        options = {}
        columns = []

        list_for_display, last_response = get_display_results(options) do |_client_options, first_row|
          response = identity_client.list_availability_domains(compartment_id)

          items = response_to_list(response, columns, include_headings: first_row) do |item|
            [item.name]
          end
          [response, items]
        end

        display_list_from_array(list_for_display, columns.length)
        warn_if_page_is_truncated(last_response)
      end
    end
  end
end

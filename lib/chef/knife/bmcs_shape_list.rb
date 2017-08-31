# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List available shapes
    class BmcsShapeList < Knife
      banner 'knife bmcs shape list (options)'

      include BmcsHelper
      include BmcsCommonOptions

      deps do
        require 'oraclebmc'
      end

      option :availability_domain,
             long: '--availability-domain AD',
             description: 'The Availability Domain of the instance.'

      option :image_id,
             long: '--image-id IMAGE',
             description: 'The OCID of the image used to boot the instance.'

      option :limit,
             long: '--limit LIMIT',
             description: 'The maximum number of items to return.'

      def run
        options = {}
        options[:availability_domain] = config[:availability_domain] if config[:availability_domain]
        options[:image_id] = config[:image_id] if config[:image_id]
        options[:limit] = config[:limit] if config[:limit]

        columns = []

        list_for_display, last_response = get_display_results(options) do |client_options|
          response = compute_client.list_shapes(compartment_id, client_options)

          items = response_to_list(response) do |item|
            [item.shape]
          end
          [response, items]
        end

        list_for_display.uniq!
        display_list_from_array(list_for_display, columns.length)
        warn_if_page_is_truncated(last_response)
      end
    end
  end
end

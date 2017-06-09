# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List available images
    class BmcsImageList < Knife
      banner 'knife bmcs image list (options)'

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

        response = compute_client.list_images(compartment_id, options)

        display_list(response, ['Display Name', 'ID', 'OS', 'OS Version']) do |image|
          [image.display_name, image.id, image.operating_system, image.operating_system_version]
        end
      end
    end
  end
end

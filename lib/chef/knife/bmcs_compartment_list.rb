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

        display_list(response, ['Display Name', 'ID']) do |item|
          [item.name, item.id]
        end
      end
    end
  end
end

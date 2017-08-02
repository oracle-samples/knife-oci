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

        response = compute_client.list_instances(compartment_id, options)

        display_list(response,
                     ['Display Name', 'State', 'ID']) do |item|
          [item.display_name,
           item.lifecycle_state,
           item.id]
        end
      end
    end
  end
end

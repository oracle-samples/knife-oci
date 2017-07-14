# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # List BMCS VCNs. Note that this lists all VCNs in a compartment, not just those that are set up as Chef nodes.
    class BmcsVcnList < Knife
      banner 'knife bmcs vcn list (options)'

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

        response = network_client.list_vcns(compartment_id, options)

        display_list(response, ['Display Name', 'ID', 'CIDR Block', 'State']) do |item|
          [item.display_name, item.id, item.cidr_block, item.lifecycle_state]
        end
      end
    end
  end
end

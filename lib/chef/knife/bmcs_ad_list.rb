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
        response = identity_client.list_availability_domains(compartment_id)

        display_list(response, []) do |item|
          [item.name]
        end
      end
    end
  end
end

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_common_options'
require 'chef/knife/bmcs_helper'

class Chef
  class Knife
    # Show deprecation warning
    class Bmcs < Knife
      banner 'knife bmcs'

      def run
        ui.warn("'knife bmcs' commands have been deprecated. Please use 'knife oci' commands instead. If 'knife oci' is not available, it can be installed by running 'chef gem install knife-oci' or 'gem install knife-oci'.")
      end
    end
  end
end

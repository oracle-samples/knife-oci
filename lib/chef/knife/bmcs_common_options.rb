# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'knife-bmcs/version'

class Chef
  class Knife
    # Options that should be included in all BMCS commands
    module BmcsCommonOptions
      def self.included(includer)
        includer.class_eval do
          option :bmcs_config_file,
                 long: '--bmcs-config-file FILE',
                 description: 'The path to the Oracle BMCS config file. Default: ~/.oraclebmc/config'

          option :bmcs_profile,
                 long: '--bmcs-profile PROFILE',
                 description: 'The profile to load from the Oracle BMCS config file. Default: DEFAULT'

          option :compartment_id,
                 long: '--compartment-id COMPARTMENT',
                 description: 'The OCID of the compartment.'
        end
      end
    end
  end
end

# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'knife-oci/version'

class Chef
  class Knife
    # Options that should be included in all OCI commands
    module OciCommonOptions
      def self.included(includer)
        includer.class_eval do
          option :region,
                 long: '--region REGION',
                 description: 'The region to make calls against.  (e.g., `us-ashburn-1`)'

          option :oci_config_file,
                 long: '--oci-config-file FILE',
                 description: 'The path to the OCI config file. Default: ~/.oci/config'

          option :oci_profile,
                 long: '--oci-profile PROFILE',
                 description: 'The profile to load from the OCI config file. Default: DEFAULT'
        end
        # all commands except compartment list get a compartment-id option
        return if includer.to_s == 'Chef::Knife::OciCompartmentList'
        includer.class_eval do
          option :compartment_id,
                 long: '--compartment-id COMPARTMENT',
                 description: 'The OCID of the compartment.'
        end
      end
    end
  end
end

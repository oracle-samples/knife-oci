# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'knife-oci/version'

# Methods to extend the instance model
module ServerDetails
  attr_accessor :compartment_name
  attr_accessor :image_name
  attr_accessor :launchtime
  attr_accessor :vcn_id
  attr_accessor :vcn_name
end

# Methods to extend the vnic model
module VnicDetails
  attr_accessor :fqdn
  attr_accessor :subnet_name
  attr_accessor :vcn_id
end

class Chef
  class Knife
    # Utility routines to fill out data for 'server show' functionality
    module OciHelperShow
      def lookup_compartment_name(compartment_id)
        compartment = identity_client.get_compartment(compartment_id, {})
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.service_code == 'NotAuthorizedOrNotFound'
      else
        compartment.data.name
      end

      def lookup_image_name(image_id)
        image = compute_client.get_image(image_id, {})
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.service_code == 'NotAuthorizedOrNotFound'
      else
        image.data.display_name
      end

      def lookup_vcn_name(vcn_id)
        vcn = network_client.get_vcn(vcn_id, {})
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.service_code == 'NotAuthorizedOrNotFound'
      else
        vcn.data.display_name
      end

      def add_server_details(server, vcn_id)
        server.extend ServerDetails

        server.launchtime = server.time_created.strftime('%a, %e %b %Y %T %Z')
        server.compartment_name = lookup_compartment_name(server.compartment_id)
        server.image_name = lookup_image_name(server.image_id)
        server.vcn_id = vcn_id
        server.vcn_name = lookup_vcn_name(vcn_id)
      end

      def add_vnic_details(vnic)
        vnic.extend VnicDetails

        begin
          subnet = network_client.get_subnet(vnic.subnet_id, {})
        rescue OCI::Errors::ServiceError => service_error
          raise unless service_error.service_code == 'NotAuthorizedOrNotFound'
        else
          vnic.fqdn = vnic.hostname_label + '.' + subnet.data.subnet_domain_name if
            subnet.data && subnet.data.subnet_domain_name && vnic.hostname_label
          vnic.subnet_name = subnet.data.display_name if
            subnet.data && subnet.data.display_name
          # piggyback the vcn_id from here, so we can avoid a few network calls
          vnic.vcn_id = subnet.data.vcn_id
        end
      end
    end
  end
end

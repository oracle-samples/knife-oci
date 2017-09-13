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

      def show_value(key, value, color = :cyan)
        ui.msg "#{ui.color(key, color)}: #{value}" if value && !value.to_s.empty?
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def display_server_info(config, instance, vnics)
        show_value('Display Name', instance.display_name)
        show_value('Instance ID', instance.id)
        show_value('Lifecycle State', instance.lifecycle_state)
        show_value('Availability Domain', instance.availability_domain)
        show_value('Compartment Name', instance.compartment_name) if instance.respond_to? :compartment_name
        show_value('Compartment ID', instance.compartment_id)
        show_value('Region', instance.region)
        show_value('Image Name', instance.image_name) if instance.respond_to? :image_name
        show_value('Image ID', instance.image_id)
        show_value('Shape', instance.shape)
        show_value('VCN Name', instance.vcn_name) if instance.respond_to? :vcn_name
        show_value('VCN ID', instance.vcn_id) if instance.respond_to? :vcn_id
        show_value('Launched', instance.launchtime) if instance.respond_to? :launchtime
        vnics.each_index do |index|
          prefix = vnics[index].is_primary ? 'Primary' : 'Secondary'
          show_value("#{prefix} Public IP Address", vnics[index].public_ip)
          show_value("#{prefix} Private IP Address", vnics[index].private_ip)
          show_value("#{prefix} Hostname", vnics[index].hostname_label)
          show_value("#{prefix} FQDN", vnics[index].fqdn) if vnics[index].respond_to? :fqdn
          show_value("#{prefix} Subnet Name", vnics[index].subnet_name) if vnics[index].respond_to? :subnet_name
        end
        show_value('Node Name', config[:chef_node_name])
      end
    end
  end
end

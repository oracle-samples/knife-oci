# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'knife-bmcs/version'

# rubocop:disable Metrics/ModuleLength
class Chef
  class Knife
    # BMCS helper module
    module BmcsHelper
      def bmcs_config
        unless @bmcs_config
          # Load config and profile first from command line args if available, then from knife.rb, then use the default.
          config_file = config[:bmcs_config_file] || Chef::Config[:knife][:bmcs_config_file] || OracleBMC::ConfigFileLoader::DEFAULT_CONFIG_FILE
          profile = config[:bmcs_profile] || Chef::Config[:knife][:bmcs_profile] || OracleBMC::ConfigFileLoader::DEFAULT_PROFILE
          @bmcs_config = OracleBMC::ConfigFileLoader.load_config(config_file_location: config_file, profile_name: profile)
          @bmcs_config.region = config[:region] if config[:region]

          @bmcs_config.additional_user_agent = "Oracle-ChefKnifeOCI/#{::Knife::BMCS::VERSION}"
        end

        @bmcs_config
      end

      def compute_client
        @compute_client ||= OracleBMC::Core::ComputeClient.new(config: bmcs_config)
      end

      def network_client
        @network_client ||= OracleBMC::Core::VirtualNetworkClient.new(config: bmcs_config)
      end

      def identity_client
        @identity_client ||= OracleBMC::Identity::IdentityClient.new(config: bmcs_config)
      end

      # Get the compartment ID first from the command line args if available, then from the knife.rb
      # file, and if neither of those is specified then use the tenancy.
      def compartment_id
        @compartment_id ||= config[:compartment_id] || Chef::Config[:knife][:compartment_id] || bmcs_config.tenancy
      end

      def error_and_exit(message)
        ui.error message
        exit(1)
      end

      def validate_required_params(required_params, params)
        missing_params = required_params.select do |param|
          params[param].nil?
        end

        error_and_exit("Missing the following required parameters: #{missing_params.join(', ').tr('_', '-')}") unless missing_params.empty?
      end

      def warn_if_page_is_truncated(response)
        ui.warn('This list has been truncated. To view more items, increase the limit.') if response.headers.include? 'opc-next-page'
      end

      # TODO: Method should be refactored to reduce complexity.
      # rubocop:disable Metrics/PerceivedComplexity
      def display_list(response, columns, warn_on_truncated: true)
        list = if response.data.nil?
                 []
               else
                 response.data.is_a?(Array) ? response.data : [response.data]
               end
        list_for_display = []

        if config[:format] == 'summary'
          width = 1

          unless columns.empty?
            columns.each do |column|
              list_for_display += [ui.color(column, :bold)]
            end

            list_for_display = list_for_display.flatten.compact
            width = columns.length
          end

          if list
            list.each do |item|
              display_item = yield(item, list_for_display)
              list_for_display += display_item if display_item
            end
          end

          puts ui.list(list_for_display, :uneven_columns_across, width)
        else
          list.each do |item|
            list_for_display += [item.to_hash]
          end

          ui.output(list_for_display)
        end

        warn_if_page_is_truncated(response) if warn_on_truncated
      end

      # Return a true or false with the confirmation result.
      # Note: user prompt is bypassed with --yes to confirm automatically.
      def confirm(prompt)
        return true if config[:yes]
        valid_responses = %w[yes no y n]
        response = nil
        3.times do
          response = ui.ask(prompt).downcase
          break if valid_responses.include? response
          ui.warn "Valid responses are #{valid_responses}"
        end
        response.match(/^y/)
      end

      def check_can_access_instance(instance_id)
        response = compute_client.get_instance(instance_id)
        error_and_exit 'Instance is already in terminated state' if response && response.data && response.data.lifecycle_state == OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED
      rescue OracleBMC::Errors::ServiceError => service_error
        raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
        error_and_exit 'Instance not authorized or not found'
      else
        return response
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

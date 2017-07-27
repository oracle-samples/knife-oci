# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'knife-bmcs/version'

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

          @bmcs_config.additional_user_agent = "Oracle-ChefKnifeBMCS/#{::Knife::BMCS::VERSION}"
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
    end
  end
end

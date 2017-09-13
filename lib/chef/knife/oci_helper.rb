# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'knife-oci/version'

# rubocop:disable Metrics/ModuleLength
class Chef
  class Knife
    # OCI helper module
    module OciHelper
      def oci_config
        unless @oci_config
          @oci_config = OCI::ConfigFileLoader.load_config(config_file_location: config_file_location, profile_name: config_file_profile)
          @oci_config.region = config[:region] if config[:region]

          @oci_config.additional_user_agent = "Oracle-ChefKnifeOCI/#{::Knife::OCI::VERSION}"
        end

        @oci_config
      end

      def config_file_location
        # Load first from command line args if available, then from knife.rb, then use the default.
        # For backwards compatibility with knife-bmcs, if oci version is not found in knife.rb, then check for bmcs version.
        config[:oci_config_file] || Chef::Config[:knife][:oci_config_file] || Chef::Config[:knife][:bmcs_config_file] || OCI::ConfigFileLoader::DEFAULT_CONFIG_FILE
      end

      def config_file_profile
        # Load first from command line args if available, then from knife.rb, then use the default.
        # For backwards compatibility with knife-bmcs, if oci version is not found in knife.rb, then check for bmcs version.
        config[:oci_profile] || Chef::Config[:knife][:oci_profile] || Chef::Config[:knife][:bmcs_profile] || OCI::ConfigFileLoader::DEFAULT_PROFILE
      end

      def compute_client
        @compute_client ||= OCI::Core::ComputeClient.new(config: oci_config)
      end

      def network_client
        @network_client ||= OCI::Core::VirtualNetworkClient.new(config: oci_config)
      end

      def identity_client
        @identity_client ||= OCI::Identity::IdentityClient.new(config: oci_config)
      end

      # Get the compartment ID first from the command line args if available, then from the knife.rb
      # file, and if neither of those is specified then use the tenancy.
      def compartment_id
        @compartment_id ||= config[:compartment_id] || Chef::Config[:knife][:compartment_id] || oci_config.tenancy
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

      def next_page_token(response)
        return response.headers['opc-next-page'] if response.headers.include? 'opc-next-page'
        nil
      end

      def get_display_results(options)
        max_results = config[:limit] ? Integer(config[:limit]) : nil

        num_fetched_results = 0
        list_for_display = []
        response = nil
        loop do
          response, new_items = yield(options)

          list_for_display += new_items
          num_fetched_results += response.data.length if response.data
          break if next_page_token(response).nil?
          break if max_results && num_fetched_results >= max_results
          options[:page] = next_page_token(response)
          options[:limit] = (max_results - num_fetched_results).to_s if max_results
        end
        [list_for_display, response]
      end

      def bold(list)
        bolded_list = []
        list.each do |column|
          bolded_list += [ui.color(column, :bold)]
        end
        bolded_list.flatten.compact
      end

      # Return data in summary mode format
      def _summary_list(list)
        list_for_display = []

        if list
          list.each do |item|
            display_item = yield(item, list_for_display)
            list_for_display += display_item if display_item
          end
        end

        list_for_display
      end

      # Return data in non-summary mode format.
      def _non_summary_list(list)
        list_for_display = []
        list.each do |item|
          list_for_display += [item.to_hash]
        end

        list_for_display
      end

      # Return a one dimensional array of data based on API response.
      # Result is compatible with display_list_from_array.
      def response_to_list(response, &block)
        list = if response.data.nil?
                 []
               else
                 response.data.is_a?(Array) ? response.data : [response.data]
               end

        return _summary_list(list, &block) if config[:format] == 'summary'
        _non_summary_list(list)
      end

      # Display a list using a one dimensional array as input
      #
      # Example output in summary mode:
      # display_list_from_array(['a','b', 'c', 'd'], 2)
      # a  b
      # c  d
      def display_list_from_array(list_for_display, num_columns)
        if config[:format] == 'summary'
          num_columns = 1 if num_columns < 1
          puts ui.list(list_for_display, :uneven_columns_across, num_columns)
        else
          ui.output(list_for_display)
        end
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
        error_and_exit 'Instance is already in terminated state' if response && response.data && response.data.lifecycle_state == OCI::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED
      rescue OCI::Errors::ServiceError => service_error
        raise unless service_error.service_code == 'NotAuthorizedOrNotFound'
        error_and_exit 'Instance not authorized or not found'
      else
        return response
      end
    end
  end
end

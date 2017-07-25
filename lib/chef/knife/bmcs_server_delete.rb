# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/bmcs_helper'
require 'chef/knife/bmcs_common_options'

# max interval for polling the server state
MAX_INTERVAL_SECONDS = 3

class Chef
  class Knife
    # Server Delete Command: Delete a BMCS instance.
    class BmcsServerDelete < Knife
      banner 'knife bmcs server delete (options)'

      include BmcsHelper
      include BmcsCommonOptions

      deps do
        require 'oraclebmc'
        require 'chef/knife/bootstrap'
      end

      option :instance_id,
             long: '--instance-id INSTANCE',
             description: 'The OCID of the instance to be deleted.'

      option :wait,
             long: '--wait SECONDS',
             description: 'Wait for the instance to be terminated. 0=infinite'

      def run
        $stdout.sync = true
        validate_required_params(%i[instance_id], config)
        wait_for = validate_wait

        confirm_deletion

        check_can_access_instance(config[:instance_id])

        terminate_instance(config[:instance_id])

        wait_for_instance_terminated(config[:instance_id], wait_for) if wait_for
      end

      def terminate_instance(instance_id)
        compute_client.terminate_instance(instance_id)

        ui.msg "Initiated delete of instance #{instance_id}"
      end

      def wait_for_instance_terminated(instance_id, wait_for)
        print ui.color('Waiting for instance to terminate...', :magenta)
        begin
          begin
            compute_client.get_instance(instance_id).wait_until(:lifecycle_state,
                                                                OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED,
                                                                get_wait_options(wait_for)) do
              show_progress
            end
          ensure
            end_progress_indicator
          end
        rescue OracleBMC::Waiter::Errors::MaximumWaitTimeExceededError
          error_and_exit 'Timeout exceeded while waiting for instance to terminate'
        rescue OracleBMC::Errors::ServiceError => service_error
          raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
          # we'll soak this exception since the terminate may have completed before we started waiting for it.
          ui.warn 'Instance not authorized or not found'
        end
      end

      def check_can_access_instance(instance_id)
        response = compute_client.get_instance(instance_id)
        error_and_exit 'Instance is already in terminated state' if response && response.data && response.data.lifecycle_state == OracleBMC::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED
      rescue OracleBMC::Errors::ServiceError => service_error
        raise unless service_error.serviceCode == 'NotAuthorizedOrNotFound'
        error_and_exit 'Instance not authorized or not found'
      end

      def validate_wait
        wait_for = nil
        if config[:wait]
          wait_for = Integer(config[:wait])
          error_and_exit 'Wait value must be 0 or greater' if wait_for < 0
        end
        wait_for
      end

      def get_wait_options(wait_for)
        opts = {
          max_interval_seconds: MAX_INTERVAL_SECONDS
        }
        opts[:max_wait_seconds] = wait_for if wait_for > 0
        opts
      end

      def confirm_deletion
        return if confirm('Delete server? (y/n)')
        error_and_exit 'Server delete canceled.'
      end

      def show_progress
        print ui.color('.', :magenta)
        $stdout.flush
      end

      def end_progress_indicator
        print ui.color("done\n", :magenta)
      end
    end
  end
end

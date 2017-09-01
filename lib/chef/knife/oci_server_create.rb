# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'chef/knife'
require 'chef/knife/oci_helper'
require 'chef/knife/oci_helper_show'
require 'chef/knife/oci_common_options'

class Chef
  class Knife
    # Server Create Command: Launch an instance and bootstrap it.
    class OciServerCreate < Knife
      banner 'knife oci server create (options)'

      include OciHelper
      include OciHelperShow
      include OciCommonOptions

      # Port for SSH - might want to parameterize this in the future.
      SSH_PORT = 22

      WAIT_FOR_SSH_INTERVAL_SECONDS = 2
      DEFAULT_WAIT_FOR_SSH_MAX_SECONDS = 180
      DEFAULT_WAIT_TO_STABILIZE_SECONDS = 40

      deps do
        require 'oci'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      option :oci_config_file,
             long: '--oci-config-file FILE',
             description: 'The path to the OCI config file. Default: ~/.oci/config'

      option :oci_profile,
             long: '--oci-profile PROFILE',
             description: 'The profile to load from the OCI config file. Default: DEFAULT'

      option :availability_domain,
             long: '--availability-domain AD',
             description: 'The Availability Domain of the instance. (required)'

      option :display_name,
             long: '--display-name NAME',
             description: "A user-friendly name for the instance. Does not have to be unique, and it's changeable."

      option :hostname_label,
             long: '--hostname-label HOSTNAME',
             description: 'The hostname for the VNIC that is created during instance launch. Used for DNS. The value is the hostname '\
                          "portion of the instance's fully qualified domain name (FQDN). Must be unique across all VNICs in the subnet "\
                          'and comply with RFC 952 and RFC 1123. The value cannot be changed, and it can be retrieved from the Vnic object.'

      option :image_id,
             long: '--image-id IMAGE',
             description: 'The OCID of the image used to boot the instance. (required)'

      option :metadata,
             long: '--metadata METADATA',
             description: 'Custom metadata key/value pairs in JSON format.'

      option :shape,
             long: '--shape SHAPE',
             description: 'The shape of an instance. The shape determines the number of CPUs, amount of memory, and other resources allocated to the instance. (required)'

      option :ssh_authorized_keys_file,
             long: '--ssh-authorized-keys-file FILE',
             description: 'A file containing one or more public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance. '\
                          'Use a newline character to separate multiple keys. The SSH keys must be in the format necessary for the authorized_keys file. This parameter '\
                          "is a convenience wrapper around the 'ssh_authorized_keys' field of the --metadata parameter. Populating both values in the same call will result "\
                          'in an error. For more info see documentation: https://docs.us-phoenix-1.oraclecloud.com/api/#/en/iaas/20160918/requests/LaunchInstanceDetails. (required)'

      option :subnet_id,
             long: '--subnet-id SUBNET',
             description: 'The OCID of the subnet. (required)'

      option :user_data_file,
             long: '--user-data-file FILE',
             description: 'A file containing data that Cloud-Init can use to run custom scripts or provide custom Cloud-Init configuration. This parameter is a convenience '\
                          "wrapper around the 'user_data' field of the --metadata parameter.  Populating both values in the same call will result in an error. For more info "\
                          'see Cloud-Init documentation: https://cloudinit.readthedocs.org/en/latest/topics/format.html.'

      option :ssh_user,
             short: '-x USERNAME',
             long: '--ssh-user USERNAME',
             description: 'The SSH username. Defaults to opc.',
             default: 'opc'

      option :ssh_password,
             short: '-P PASSWORD',
             long: '--ssh-password PASSWORD',
             description: 'The SSH password'

      option :identity_file,
             short: '-i FILE',
             long: '--identity-file IDENTITY_FILE',
             description: 'The SSH identity file used for authentication. This must correspond to a public SSH key provided by --ssh-authorized-keys-file. (required)'

      option :chef_node_name,
             short: '-N NAME',
             long: '--node-name NAME',
             description: 'The Chef node name for the new node. If not specified, the instance display name will be used.'

      option :run_list,
             short: '-r RUN_LIST',
             long: '--run-list RUN_LIST',
             description: 'A comma-separated list of roles or recipes.',
             proc: ->(o) { o.split(/[\s,]+/) },
             default: []

      option :wait_to_stabilize,
             long: '--wait-to-stabilize SECONDS',
             description: "Duration to pause after SSH becomes reachable. Default: #{DEFAULT_WAIT_TO_STABILIZE_SECONDS}"

      option :wait_for_ssh_max,
             long: '--wait-for-ssh-max SECONDS',
             description: "The maximum time to wait for SSH to become reachable. Default: #{DEFAULT_WAIT_FOR_SSH_MAX_SECONDS}"

      def run
        $stdout.sync = true
        validate_required_params(%i[availability_domain image_id shape subnet_id identity_file ssh_authorized_keys_file], config)
        validate_wait_options

        metadata = merge_metadata
        error_and_exit 'SSH authorized keys must be specified.' unless metadata['ssh_authorized_keys']

        request = OCI::Core::Models::LaunchInstanceDetails.new
        request.availability_domain = config[:availability_domain]
        request.compartment_id = compartment_id
        request.display_name = config[:display_name]
        request.hostname_label = config[:hostname_label]
        request.image_id = config[:image_id]
        request.metadata = metadata
        request.shape = config[:shape]
        request.subnet_id = config[:subnet_id]

        response = compute_client.launch_instance(request)
        instance = response.data

        ui.msg "Launched instance '#{instance.display_name}' [#{instance.id}]"
        show_value('Display Name', instance.display_name)
        show_value('Instance ID', instance.id)
        show_value('Availability Domain', instance.availability_domain)
        show_value('Compartment ID', instance.compartment_id)
        show_value('Region', instance.region)
        show_value('Image ID', instance.image_id)
        show_value('Shape', instance.shape)

        instance = wait_for_instance_running(instance.id)

        ui.msg "Instance '#{instance.display_name}' is now running."

        vnic = get_vnic(instance.id, instance.compartment_id)
        show_value('Public IP Address', vnic.public_ip)
        show_value('Private IP Address', vnic.private_ip)

        unless wait_for_ssh(vnic.public_ip, SSH_PORT, WAIT_FOR_SSH_INTERVAL_SECONDS, config[:wait_for_ssh_max])
          error_and_exit 'Timed out while waiting for SSH access.'
        end

        wait_to_stabilize

        config[:chef_node_name] = instance.display_name unless config[:chef_node_name]

        ui.msg "Bootstrapping with node name '#{config[:chef_node_name]}'."

        # TODO: Consider adding a use_private_ip option.
        bootstrap(vnic.public_ip)

        ui.msg "Created and bootstrapped node '#{config[:chef_node_name]}'."
        ui.msg "\n"

        display_server_info(config, instance, [vnic])
      end

      def bootstrap(name)
        bootstrap = Chef::Knife::Bootstrap.new

        bootstrap.name_args = [name]
        bootstrap.config[:chef_node_name] = config[:chef_node_name]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_password] = config[:ssh_password]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:use_sudo] = true
        bootstrap.config[:ssh_gateway] = config[:ssh_user] + '@' + name
        bootstrap.config[:run_list] = config[:run_list]

        bootstrap.config[:yes] = true if config[:yes]

        bootstrap.run
      end

      def validate_wait_option(p, default)
        arg_name = "--#{p.to_s.tr('_', '-')}"
        config[p] = config[p].to_s.empty? ? default : Integer(config[p])
        error_and_exit "#{arg_name} must be 0 or greater" if config[p] < 0
      rescue
        error_and_exit "#{arg_name} must be numeric"
      end

      def validate_wait_options
        validate_wait_option(:wait_to_stabilize, DEFAULT_WAIT_TO_STABILIZE_SECONDS)
        validate_wait_option(:wait_for_ssh_max, DEFAULT_WAIT_FOR_SSH_MAX_SECONDS)
      end

      def wait_to_stabilize
        # This extra sleep even after getting SSH access is necessary. It's not clear why, but without it we often get
        # errors about missing a password for ssh, or sometimes errors during bootstrapping. (Note that plugins for other
        # cloud providers have similar sleeps.)
        Kernel.sleep(config[:wait_to_stabilize])
      end

      def wait_for_ssh(hostname, ssh_port, interval_seconds, max_time_seconds)
        print ui.color('Waiting for ssh access...', :magenta)

        end_time = Time.now + max_time_seconds

        begin
          while Time.now < end_time
            return true if can_ssh(hostname, ssh_port)

            show_progress
            sleep interval_seconds
          end
        ensure
          end_progress_indicator
        end

        false
      end

      def can_ssh(hostname, ssh_port)
        socket = TCPSocket.new(hostname, ssh_port)
        # Wait up to 5 seconds.
        readable = IO.select([socket], nil, nil, 5)
        if readable
          content = socket.gets
          # Make sure some content was actually returned.
          return true unless content.nil? || content.empty?
        else
          false
        end
      rescue SocketError, IOError, Errno::ETIMEDOUT, Errno::EPERM, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNRESET, Errno::ENOTCONN
        false
      ensure
        socket && socket.close
      end

      def wait_for_instance_running(instance_id)
        print ui.color('Waiting for instance to reach running state...', :magenta)

        begin
          response = compute_client.get_instance(instance_id).wait_until(:lifecycle_state,
                                                                         OCI::Core::Models::Instance::LIFECYCLE_STATE_RUNNING,
                                                                         max_interval_seconds: 3) do |poll_response|
            if poll_response.data.lifecycle_state == OCI::Core::Models::Instance::LIFECYCLE_STATE_TERMINATED ||
               poll_response.data.lifecycle_state == OCI::Core::Models::Instance::LIFECYCLE_STATE_TERMINATING
              throw :stop_succeed
            end

            show_progress
          end
        ensure
          end_progress_indicator
        end

        if response.data.lifecycle_state != OCI::Core::Models::Instance::LIFECYCLE_STATE_RUNNING
          error_and_exit 'Instance failed to provision.'
        end

        response.data
      end

      # Return the first VNIC found (which should be the only VNIC).
      def get_vnic(instance_id, compartment)
        compute_client.list_vnic_attachments(compartment, instance_id: instance_id).each do |response|
          response.data.each do |vnic_attachment|
            return network_client.get_vnic(vnic_attachment.vnic_id).data
          end
        end
      end

      def merge_metadata
        metadata = config[:metadata]

        if metadata
          begin
            metadata = JSON.parse(metadata)
          rescue JSON::ParserError
            error_and_exit('Metadata value must be in JSON format. Example: \'{"key1":"value1", "key2":"value2"}\'')
          end
        else
          metadata = {}
        end

        ssh_authorized_keys = get_file_content(:ssh_authorized_keys_file)
        user_data = get_file_content(:user_data_file)
        user_data = Base64.strict_encode64(user_data) if user_data

        if ssh_authorized_keys
          error_and_exit('Cannot specify ssh-authorized-keys as part of both --ssh-authorized-keys-file and --metadata.') if metadata.key? 'ssh_authorized_keys'
          metadata['ssh_authorized_keys'] = ssh_authorized_keys
        end

        if user_data
          error_and_exit('Cannot specify CloudInit user-data as part of both --user-data-file and --metadata.') if metadata.key? 'user_data'
          metadata['user_data'] = user_data
        end

        metadata
      end

      def show_progress
        print ui.color('.', :magenta)
        $stdout.flush
      end

      def end_progress_indicator
        print ui.color("done\n", :magenta)
      end

      def get_file_content(file_name_param)
        file_name = config[file_name_param]
        return if file_name.nil?

        file_name = File.expand_path(file_name)
        File.open(file_name, 'r').read
      end
    end
  end
end

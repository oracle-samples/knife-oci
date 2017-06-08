# Chef Knife Plugin for Oracle BMCS

## About

The knife-bmcs plugin allows users to interact with Oracle Bare Metal Cloud Services through Chef Knife.

The project is open source and maintained by Oracle Corp. The home page for the project is [here](https://docs.us-phoenix-1.oraclecloud.com/Content/API/SDKDocs/knifeplugin.htm).

## Commands

- Launch a BMCS instance and bootstrap it as a Chef node:
 `knife bmcs server create`
- List BMCS instances in a given compartment. **Note:** All instances in the compartment are returned, not only those that are Chef nodes:
  `knife bmcs server list`
- List the images in a compartment:
`knife bmcs image list`
- List the shapes that may be used for a particular image type:
 `knife bmcs shape list`
- List the availability domains for your tenancy:
  `knife bmcs ad list`

## Requirements

Linux and Mac are supported. Windows is not supported at this time.

## Installation

Install from RubyGems with:

    chef gem install knife-bmcs

Or:

    gem install knife-bmcs

**Note:** The plugin depends on the Oracle BMCS Ruby SDK. Information about that SDK can be found [here](https://docs.us-phoenix-1.oraclecloud.com/Content/API/SDKDocs/rubysdk.htm).

## Setup

A config file is required to use Bare Metal Cloud Services commands. See the instructions for creating a config file [here](https://docs.us-phoenix-1.oraclecloud.com/Content/API/Concepts/sdkconfig.htm).

By default, the config file will be loaded from ~/.oraclebmc/config. Alternate locations can be provided as an argument to each command using `--bmcs-config-file`, or as an entry in your knife.rb file. You can also specify a profile with `--bmcs-profile`.

## Setting the Compartment

Each BMCS command requires a compartment ID, which will default to the root compartment. If you do not have the correct permissions and you do not specify a different compartment, then you will receive an authorization error.

A compartment ID can be provided with each BMCS command using `--compartment-id`, or it can be provided in your knife.rb. If a compartment ID is set in both places, then the ID specified in the command will take precedence.

## Knife.rb values

The following example shows the available knife.rb settings for the BMCS Knife Plugin. All of these are optional.

    knife[:bmcs_config_file] = '~/.oraclebmc/my_alternate_config'
    knife[:bmcs_profile] = 'MY_ALTERNATE_PROFILE'
    knife[:compartment_id] = 'ocid1.compartment.oc1..aaaaaaaalsyenka3grgpvvmqwjshig5abzx3jnbvixxxzx373ehwdj7o5arc'

## Using the Server Create Command

The following example shows how to launch and bootstrap an Oracle Linux image:

    knife bmcs server create
      --availability-domain 'kIdk:PHX-AD-1'
      --compartment-id 'ocidv1:tenancy:oc1:phx:1460406592660:aaaaaaaab4faofrfkxecohhjuivjq26a13'
      --image-id 'ocid1.image.oc1.phx.aaaaaaaaqutj4qjxihpl4mboabsa27mrpusygv6gurp47katabcvljmq3puq'
      --shape 'VM.Standard1.1'
      --subnet-id 'ocid1.subnet.oc1.phx.aaaaaaaaxlc5cv7ewqr343ms4lvcpxr4lznsf4cbs2565abcm23d3cfebrex'
      --ssh-authorized-keys-file ~/.keys/instance_keys.pub
      --display-name myinstance
      --identity-file ~/.keys/instance_keys
      --run-list 'recipe[my_cookbook::my_recipe]'

When using the `knife bmcs server create` command, you must specify a public key using `--ssh-authorized-keys-file` and the corresponding private key using `--identity-file`. For more information, see [Managing Key Pairs on Linux Instances](https://docs.us-phoenix-1.oraclecloud.com/Content/Compute/Tasks/managingkeypairs.htm).

Notes about the `knife bmcs server create` command:

 - All Oracle-provided Linux images are supported. Windows images are not supported at this time.
 - Bootstrapping is done through SSH only, and uses the public IP address.
 - For Ubuntu images, the user is usually 'ubuntu' instead of 'opc'.

## Help

See the “Questions or Feedback?” section [here](https://docs.us-phoenix-1.oraclecloud.com/Content/API/SDKDocs/knifeplugin.htm).

## Changes

See [CHANGELOG](/CHANGELOG.md).

## Contributing

knife-bmcs is an open source project. See [CONTRIBUTING](/CONTRIBUTING.md) for details.

Oracle gratefully acknowledges the contributions to knife-bmcs that have been made by the community.

## Known Issues

You can find information on any known issues with the SDK [here](https://docs.us-phoenix-1.oraclecloud.com/Content/knownissues.htm) and under the “Issues” tab of this GitHub repository.

## License

Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.

This SDK and sample is dual licensed under the Universal Permissive License 1.0 and the Apache License 2.0.

See [LICENSE](/LICENSE.txt) for more details.

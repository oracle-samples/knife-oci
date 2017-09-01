# This is a example knife.rb with fake data.
# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

log_level                :info
log_location             STDOUT

chef_server_url          'https://111.111.111.111/organizations/myinc'

knife[:oci_config_file] = ENV['KNIFE_OCI_CONFIG_FILE']
knife[:oci_profile] = ENV['KNIFE_OCI_PROFILE']
knife[:compartment_id] = ENV['KNIFE_OCI_COMPARTMENT']

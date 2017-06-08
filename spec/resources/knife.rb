# This is a example knife.rb with fake data.
# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

log_level                :info
log_location             STDOUT

chef_server_url          'https://111.111.111.111/organizations/myinc'

knife[:bmcs_config_file] = ENV['KNIFE_BMCS_CONFIG_FILE']
knife[:compartment_id] = ENV['KNIFE_BMCS_COMPARTMENT']

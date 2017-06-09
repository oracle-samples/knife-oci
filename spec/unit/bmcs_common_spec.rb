# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'json'
require 'chef/knife/bmcs_server_list'
require 'oraclebmc'
require './spec/spec_helper'

describe 'bmcs common utilities' do
  let(:knife_bmcs_server_list) { Chef::Knife::BmcsServerList.new }

  describe 'loading of config values' do
    it 'loads bmcs config from knife config' do
      knife_bmcs_server_list.config = { bmcs_config_file: DUMMY_CONFIG_FILE }
      expect(knife_bmcs_server_list.bmcs_config.tenancy).to eq('tenancy_for_default_profile')
    end

    it 'loads bmcs profile from knife config' do
      knife_bmcs_server_list.config = {
        bmcs_config_file: DUMMY_CONFIG_FILE,
        bmcs_profile: 'SECOND_PROFILE'
      }
      expect(knife_bmcs_server_list.bmcs_config.tenancy).to eq('tenancy_for_second_profile')
    end
  end
end

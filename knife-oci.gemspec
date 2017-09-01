# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'knife-oci/version'

Gem::Specification.new do |s|
  s.name        = 'knife-oci'
  s.version     = Knife::OCI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Oracle']
  s.email       = ['brian.gustafson@oracle.com', 'joe.levy@oracle.com']
  s.homepage    = 'https://github.com/oracle/knife-oci'
  s.summary     = 'Chef Knife Plugin for Oracle Cloud Infrastructure'
  s.description = ''
  s.licenses    = ['UPL-1.0', 'Apache-2.0']

  s.required_ruby_version = '>= 2.2.0'

  s.add_runtime_dependency 'oci', '~> 2.0', '>= 2.0.0'

  s.require_paths = ['lib']
  s.files         = Dir['./lib/**/*.rb', 'LICENSE.txt']
end

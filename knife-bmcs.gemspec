# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'knife-bmcs/version'

Gem::Specification.new do |s|
  s.name        = 'knife-bmcs'
  s.version     = Knife::BMCS::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Oracle']
  s.email       = ['brian.gustafson@oracle.com', 'joe.levy@oracle.com']
  s.homepage    = 'https://github.com/oracle/knife-bmcs'
  s.summary     = 'Chef Knife Plugin for Oracle Bare Metal Cloud Services'
  s.description = ''
  s.licenses    = ['UPL-1.0', 'Apache-2.0']

  s.required_ruby_version = '>= 2.2.0'

  s.add_runtime_dependency 'oraclebmc', '~> 1.0', '>= 1.2.1'

  s.require_paths = ['lib']
  s.files         = Dir['./lib/**/*.rb', 'LICENSE.txt']
end

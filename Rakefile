# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.

require 'rubocop/rake_task'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new

task :install do
  sh %(chef gem build knife-bmcs.gemspec)
  sh %(chef gem install knife-bmcs-*.gem)
end

desc 'Run all unit tests.'
RSpec::Core::RakeTask.new(:unit) do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
end

desc 'Run all integration tests.'
RSpec::Core::RakeTask.new(:integ) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

task default: %i[unit rubocop]

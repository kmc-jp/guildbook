require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'

require 'sinatra/asset_pipeline/task'
require "#{File.dirname(__FILE__)}/lib/app"

Sinatra::AssetPipeline::Task.define! GuildBook::App


task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/*_test.rb']
  test.verbose = true
end

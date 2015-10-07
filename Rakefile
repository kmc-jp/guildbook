require 'rubygems'
require 'bundler/setup'
require 'sinatra/asset_pipeline/task'
require "#{File.dirname(__FILE__)}/lib/app"

task :bower do
  sh 'bower install --production'
end

Sinatra::AssetPipeline::Task.define!(GuildBook::App)
Rake::Task['assets:precompile'].enhance(['bower'])

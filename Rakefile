require 'rubygems'
require 'bundler/setup'
require 'sinatra/asset_pipeline/task'
require "#{File.dirname(__FILE__)}/lib/app"

task :'npm:install' do
  sh 'npm install'
end

Sinatra::AssetPipeline::Task.define!(GuildBook::App)
Rake::Task['assets:precompile'].enhance(['npm:install'])

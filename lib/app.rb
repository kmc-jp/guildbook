require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/asset_pipeline'

require 'haml'
require_relative 'view_helpers'
require_relative 'date_ext'

require 'sass'
require 'compass'
require 'bootstrap-sass'

require_relative 'user'

module GuildBook
  class App < Sinatra::Base
    set :sessions, true

    register Sinatra::ConfigFile
    config_file '../config/guildbook*.yml'

    set :assets_prefix, %W[assets vendor/assets #{Compass::Frameworks[:bootstrap].path}/vendor/assets]
    register Sinatra::AssetPipeline

    set :views, "#{File.dirname(__FILE__)}/../views"
    set :public_folder, "#{File.dirname(__FILE__)}/../public"

    get '/' do
      haml :index, locals: {users: user_repo.find(params['q'], params['all']).sort_by {|u| u['uid'].first }}
    end

    get '/:uid' do |uid|
      haml :detail, locals: {user: user_repo.get(uid)}
    end

    get '/:uid/edit' do |uid|
      haml :edit, locals: {user: user_repo.get(uid)}
    end

    post '/:uid/edit' do |uid|
      user_repo.edit(uid, params['$bind_uid'], params['$bind_password'], params)

      redirect absolute_uri(uid)
    end

    private

    def absolute_uri(*path)
      url(path.join('/'))
    end

    def user_repo
      UserRepo.new(settings.ldap)
    end

    def remote_user
      request.env['REMOTE_USER']
    end

    def brand
      settings.brand || {}
    end
  end
end

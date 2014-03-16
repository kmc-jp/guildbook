require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/asset_pipeline'

require 'haml'
require_relative 'view_helpers'

require 'sass'
require 'compass'
require 'bootstrap-sass'

require_relative 'user'

module GuildBook
  class App < Sinatra::Base
    set :sessions, true

    register Sinatra::ConfigFile
    config_file '../config/guildbook*.yml'

    set :assets_prefix, %W[src/assets vendor/assets #{Compass::Frameworks['bootstrap'].path}/vendor/assets]
    register Sinatra::AssetPipeline

    def absolute_uri(*path)
      url(path.join('/'))
    end

    get '/' do
      haml :index, locals: {users: user_repo.find(params['q']).sort_by {|u| u['uid'].first }}
    end

    get '/:uid' do |uid|
      haml :detail, locals: {user: user_repo.get(uid)}
    end

    get '/:uid/edit' do |uid|
      haml :edit, locals: {user: user_repo.get(uid)}
    end

    post '/:uid/edit' do |uid|
      user_repo.edit(uid, params['password'], params)

      redirect absolute_uri(uid)
    end

    private

    def user_repo
      UserRepo.new(settings.ldap)
    end

  end
end

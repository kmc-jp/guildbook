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
    config_file "#{File.dirname(__FILE__)}/../config/guildbook*.yml"

    set :assets_prefix, %W[assets vendor/assets #{Compass::Frameworks[:bootstrap].path}/vendor/assets]
    register Sinatra::AssetPipeline

    set :views, "#{File.dirname(__FILE__)}/../views"
    set :public_folder, "#{File.dirname(__FILE__)}/../public"

    get '/' do
      users = user_repo.find(params['q'], params['all'])

      sort_keys = ((params['sort'] || '').split(',') + ['uid']).map do |key|
        key[0] != '-' ? [key, 1] : [key[1..-1], -1]
      end

      users.sort! do |u, v|
        sort_keys.inject(0) do |x, (key, ord)|
          x.nonzero? || (u[key] <=> v[key]) * ord
        end
      end

      haml :index, locals: {users: users}
    end

    get '/:uid' do |uid|
      haml :detail, locals: {user: user_repo.get(uid)}
    end

    get '/:uid/edit' do |uid|
      haml :edit, locals: {user: user_repo.get(uid), error: nil}
    end

    post '/:uid/edit' do |uid|
      begin
        user_repo.edit(uid, params['$bind_uid'], params['$bind_password'], params)
        redirect absolute_uri(uid)
      rescue
        user = user_repo.get(uid)
        params.each do
          |k, v| user[k] = [v]
        end
        haml :edit, locals: {user: user, error: $!}
      end
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

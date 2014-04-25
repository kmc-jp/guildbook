require 'uri'

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
require_relative 'utils'

module GuildBook
  class App < Sinatra::Base
    set :sessions, true

    register Sinatra::ConfigFile
    config_file "#{File.dirname(__FILE__)}/../config/guildbook*.yml"

    set :assets_prefix, %W[assets vendor/assets #{Compass::Frameworks[:bootstrap].path}/vendor/assets]
    set :assets_css_compressor, :sass
    set :assets_js_compressor, :closure
    configure :production do
      assets_uri = URI.parse(settings.assets_uri)
      Sprockets::Helpers.protocol = assets_uri.scheme
      Sprockets::Helpers.asset_host = assets_uri.host
      Sprockets::Helpers.prefix = assets_uri.path
      # port is ignored -- needs patch sprockets-helpers
    end
    register Sinatra::AssetPipeline

    set :views, "#{File.dirname(__FILE__)}/../views"
    set :public_folder, "#{File.dirname(__FILE__)}/../public"

    get '/' do
      sort_keys = [params['sort'], settings.ui['default_sort_keys']].compact.flat_map(&Utils.method(:parse_sortkeys))

      users = user_repo.find(params['q'], params['all']).sort do |u, v|
        sort_keys.inject(0) do |x, (key, ord)|
          x.nonzero? || (u[key] <=> v[key]) * ord
        end
      end

      haml :index, locals: {users: users}
    end

    get '/:uid' do |uid|
      pass if uid =~ /^!/
      haml :detail, locals: {user: user_repo.get(uid)}
    end

    get '/:uid/edit' do |uid|
      pass if uid =~ /^!/
      haml :edit, locals: {user: user_repo.get(uid), error: nil}
    end

    post '/:uid/edit' do |uid|
      pass if uid =~ /^!/
      begin
        bind_uid = params.delete('$bind_uid')
        bind_password = params.delete('$bind_password')
        user_repo.edit(uid, bind_uid, bind_password, params)
        redirect absolute_uri(uid)
      rescue
        user = user_repo.get(uid)
        params.each do |k, v|
          user[k] = [v]
        end
        haml :edit, locals: {user: user, error: $!}
      end
    end

    private

    def absolute_uri(*path)
      uri(path.join('/'))
    end

    def user_repo
      UserRepo.new(settings.ldap_uri)
    end

    def remote_user
      request.env['REMOTE_USER']
    end
  end
end

# -*- coding: utf-8 -*-
require 'uri'

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/asset_pipeline'
require 'sinatra/content_for'

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

    set :root, File.expand_path('..', File.dirname(__FILE__))
    set :views, -> { File.join(root, 'views') }
    set :public_folder, -> { File.join(root, 'public') }

    set :assets_precompile, %w(app.js app.css univ.css *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2)
    set :assets_css_compressor, :sass
    set :assets_js_compressor, :closure
    register Sinatra::AssetPipeline

    helpers Sinatra::ContentFor

    configure do
      self.sprockets.append_path File.join(self.root, 'bower_components')

      Sprockets::Helpers.configure do |config|
        assets_uri = URI.parse(settings.assets_uri)
        config.protocol = assets_uri.scheme
        config.asset_host = assets_uri.host
        config.prefix = assets_uri.path
        # port is ignored -- needs patch sprockets-helpers
      end
    end

    set :haml, escape_html: true

    before do
      navlinks << {
        href: absolute_uri(),
        icon: 'list-alt',
        text: '一覧'
      }

      if remote_user
        navlinks << {
          href: absolute_uri(remote_user),
          icon: 'user',
          text: remote_user
        }
      end
    end

    get '/' do
      sort_keys = [params['sort'], settings.ui['default_sort_keys']].compact.flat_map(&Utils.method(:parse_sortkeys))

      users = user_repo.search(params['q'], params['all']).sort do |u, v|
        sort_keys.inject(0) do |x, (key, ord)|
          x.nonzero? || (u[key].map(&Utils.method(:tokenize)) <=> v[key].map(&Utils.method(:tokenize))) * ord
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
        # textinput to lines
        params['sshPublicKey'] = params['sshPublicKey'].strip().split(/\r?\n/)
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
      UserRepo.new(settings.ldap_uri['users'])
    end

    def remote_user
      request.env['REMOTE_USER']
    end

    def navlinks
      @navlinks ||= []
    end
  end
end

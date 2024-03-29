# -*- coding: utf-8 -*-
require 'pathname'
require 'uri'

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/content_for'

require 'haml'
require_relative 'view_helpers'
require_relative 'date_ext'
require_relative 'user'
require_relative 'utils'
require_relative 'webpack_helpers'
require_relative 'ku_departments_helpers'

module GuildBook
  class App < Sinatra::Base
    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    register Sinatra::ConfigFile
    config_file "#{File.dirname(__FILE__)}/../config/guildbook*.yml"

    set :root, File.expand_path('..', File.dirname(__FILE__))
    set :views, -> { File.join(root, 'views') }
    set :public_folder, -> { File.join(root, 'public') }

    helpers Sinatra::ContentFor
    helpers WebpackHelpers
    helpers DepartmentHelpers
    helpers ViewHelpers

    set :haml, escape_html: true

    before do
      navlinks << {
        href: absolute_uri(),
        icon: 'users',
        text: '一覧',
        order: 0,
      }

      if remote_user
        navlinks << {
          href: absolute_uri(remote_user),
          icon: 'address-card',
          text: remote_user,
          order: 1,
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
      haml :editauth, locals: {user: user_repo.get(uid), error: nil}
    end

    post '/:uid/edit' do |uid|
      pass if uid =~ /^!/

      bind_uid = params.delete('$bind_uid')
      bind_password = params.delete('$bind_password')
      if params['action'] == 'auth'
        begin
          user_info = user_repo.get_auth(uid, bind_uid, bind_password)
          haml :edit, locals: {user: user_info, error: nil}
        rescue
          user = user_repo.get(uid)
          params.each do |k, v|
            user[k] = [v]
          end
          haml :editauth, locals: {user: user, error: $!}
        end
      else
        begin
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
    end

    private

    def absolute_uri(*path)
      uri(path.join('/'))
    end

    def user_repo
      UserRepo.new(settings.ldap_uri['users'])
    end

    def remote_user
      request.env['REMOTE_USER'] || request.env['HTTP_X_FORWARDED_USER']
    end

    def navlinks
      @navlinks ||= []
    end
  end
end

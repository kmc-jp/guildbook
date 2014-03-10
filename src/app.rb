require 'uri'

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/asset_pipeline'

require 'net/ldap'
require 'net/ldap/dn'
require_relative 'ldap_ext'

require 'haml'
require_relative 'view_helpers'

require 'sass'
require 'compass'
require 'bootstrap-sass'

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

    def get_users(filter = nil)
      ldap_conn do |conn|
        uidFilter = Net::LDAP::Filter.present('uid')
        conn.search(filter: filter ? filter & uidFilter : uidFilter,
                    attributes: ['*'])
      end.collect(&:fix_encoding!)
    end

    def get_user(uid)
      ldap_conn do |conn|
        conn.search(filter: Net::LDAP::Filter.eq('uid', uid),
                    attributes: ['*']).first or raise Sinatra::NotFound
      end.fix_encoding!
    end

    get '/' do
      users = get_users(~Net::LDAP::Filter.present('shadowExpire'))
      haml :index, locals: {users: users.sort_by {|u| u['uid'].first }}
    end

    get '/:uid' do |uid|
      haml :detail, locals: {user: get_user(uid)}
    end

    get '/:uid/edit' do |uid|
      haml :edit, locals: {user: get_user(uid)}
    end

    post '/:uid/edit' do |uid|
      attrs = %w[
        cn
        sn sn;lang-ja sn;lang-ja;phonetic
        givenName givenName;lang-ja givenName;lang-ja;phonetic
        kmcUnivesityDepartment kmcUniversityStatus kmcUniversityMatric
        alias title kmcGeneration description
        postalCode postalAddress
        mobile homePhone
      ]

      params['cn'] = "#{params['givenName']} #{params['sn']}"

      ldap_conn do |conn|
        dn = Net::LDAP::DN.new('uid', params['uid'], conn.base)

        conn.bind(method: :simple, username: dn, password: params['password'])
        attrs.each do |attr|
          conn.replace_attribute(dn, attr, params[attr])
        end
      end

      redirect absolute_uri(uid)
    end

    private

    def ldap_conn(opt = {}, &block)
      ldap_uri = URI.parse(settings.ldap)

      opt = {
        host: ldap_uri.host,
        port: ldap_uri.port,
        base: ldap_uri.dn,
        encryption: ldap_uri.is_a?(URI::LDAPS) ? :simple_tls : :plaintext
      }.merge(opt)

      Net::LDAP.open(opt, &block)
    end
  end
end

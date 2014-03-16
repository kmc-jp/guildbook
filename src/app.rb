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

    def find_users(filter = nil)
      Net::LDAP.open_uri(settings.ldap) do |conn|
        uidFilter = Net::LDAP::Filter.present('uid')
        conn.search(filter: filter ? filter & uidFilter : uidFilter,
                    attributes: ['*'])
      end.collect(&:fix_encoding!)
    end

    def get_user(uid)
      Net::LDAP.open_uri(settings.ldap) do |conn|
        conn.search(filter: Net::LDAP::Filter.eq('uid', uid),
                    attributes: ['*']).first or raise Sinatra::NotFound
      end.fix_encoding!
    end

    def edit_user(uid, password, attrs)
      attrs['cn'] = "#{attrs['givenName']} #{attrs['sn']}"

      Net::LDAP.open_uri(settings.ldap) do |conn|
        dn = Net::LDAP::DN.new('uid', uid, conn.base)

        conn.bind(method: :simple, username: dn, password: password)
        EDITABLE_ATTRS.each do |n|
          conn.replace_attribute(dn, n, attrs[n])
        end
      end
    end

    SEARCH_ATTRS = %w[
      uid
      sn sn;lang-ja x-kmc-PhoneticSurname
      givenName givenName;lang-ja x-kmc-PhoneticGivenName
    ]

    get '/' do
      filter = ~Net::LDAP::Filter.present('shadowExpire')
      if query = params['q']
        filter &= SEARCH_ATTRS.collect {|attr|
          Net::LDAP::Filter.contains(attr, query)
        }.inject {|filters, filter|
          filters | filter
        }
      end
      users = find_users(filter)
      haml :index, locals: {users: users.sort_by {|u| u['uid'].first }}
    end

    get '/:uid' do |uid|
      haml :detail, locals: {user: get_user(uid)}
    end

    get '/:uid/edit' do |uid|
      haml :edit, locals: {user: get_user(uid)}
    end

    EDITABLE_ATTRS = %w[
      cn
      sn sn;lang-ja x-kmc-PhoneticSurname
      givenName givenName;lang-ja x-kmc-PhoneticGivenName
      x-kmc-UnivesityDepartment x-kmc-UniversityStatus x-kmc-UniversityMatricYear
      alias title x-kmc-Generation description
      postalCode postalAddress
      mobile homePhone
    ]

    post '/:uid/edit' do |uid|
      edit_user(uid, params['password'], params)

      redirect absolute_uri(uid)
    end

  end
end

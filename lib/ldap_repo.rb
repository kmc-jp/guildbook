require 'net/ldap'
require 'net/ldap/dn'
require_relative 'ldap_ext'

module GuildBook
  class LdapRepo
    attr_reader :uri

    def initialize(uri)
      @uri = uri
    end

    def do_search(filter, attributes=['*'])
      Net::LDAP.open_uri(uri) do |conn|
        conn.search(filter: filter, attributes: attributes)
      end.collect(&:fix_encoding!)
    end

    def do_search_auth(uid, bind_uid, bind_password, filter, attributes=['*'])
      # or raise Sinatra::NotFound
      Net::LDAP.open_uri(uri) do |conn|
        dn = Net::LDAP::DN.new('uid', uid, conn.base)
        bind_dn = Net::LDAP::DN.new('uid', bind_uid, conn.base)

        if !conn.bind(method: :simple, username: bind_dn, password: bind_password)
          raise Error, conn.get_operation_result.message
        end
        conn.search(filter: filter, attributes: attributes)
      end.collect(&:fix_encoding!)
    end

    class Error < ::StandardError; end
  end
end

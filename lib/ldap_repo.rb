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

    class Error < ::StandardError; end
  end
end

require 'net/ldap'
require 'net/ldap/dn'
require_relative 'ldap_ext'

require_relative 'date_ext'

module GuildBook
  class UserRepo
    def initialize(uri)
      @uri = uri
    end

    def find(query = nil, include_inactive = true)
      filter = Net::LDAP::Filter.present('uid')

      if query and (query = query.strip) and !query.empty?
        filter &= SEARCH_ATTRS.collect {|attr| Net::LDAP::Filter.contains(attr, query) }.inject(:|)
      end

      if !include_inactive
        filter &= ~Net::LDAP::Filter.present('shadowExpire')
      end

      Net::LDAP.open_uri(@uri) do |conn|
        conn.search(filter: filter, attributes: ['*'])
      end.collect(&:fix_encoding!)
    end

    def get(uid)
      Net::LDAP.open_uri(@uri) do |conn|
        conn.search(filter: Net::LDAP::Filter.eq('uid', uid),
                    attributes: ['*']).first or raise Sinatra::NotFound
      end.fix_encoding!
    end

    def edit(uid, bind_uid, bind_password, attrs)
      attrs['cn'] = "#{attrs['givenName']} #{attrs['sn']}"
      attrs['x-kmc-Lodging'] = attrs['x-kmc-Lodging'] ? 'TRUE' : 'FALSE' # fixme

      Net::LDAP.open_uri(@uri) do |conn|
        dn = Net::LDAP::DN.new('uid', uid, conn.base)
        bind_dn = Net::LDAP::DN.new('uid', bind_uid, conn.base)

        if !conn.bind(method: :simple, username: bind_dn, password: bind_password)
          raise Error, conn.get_operation_result.message
        end

        attrs.each do |key, value|
          if EDITABLE_ATTRS.include?(key.split(';').first)
            if value.empty?
              if !conn.delete_attribute(dn ,key) and conn.get_operation_result.code != 16 # no such attribute
                raise Error, conn.get_operation_result.message
              end
            else
              if !conn.replace_attribute(dn, key, value)
                raise Error, conn.get_operation_result.message
              end
            end
          end
        end

        conn.replace_attribute(dn, 'x-kmc-LastModified', DateTime.now.generalized_time)
      end
    end

    class Error < ::StandardError; end

    private

    SEARCH_ATTRS = %w[uid name]

    EDITABLE_ATTRS = %w[
      cn
      sn x-kmc-PhoneticSurname givenName x-kmc-PhoneticGivenName
      x-kmc-UniversityDepartment x-kmc-UniversityStatus x-kmc-UniversityMatricYear
      x-kmc-Alias title x-kmc-Generation description
      postalCode postalAddress x-kmc-Lodging
      telephoneNumber
    ]
  end
end

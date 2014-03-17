require 'net/ldap'
require 'net/ldap/dn'
require_relative 'ldap_ext'

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

    def edit(uid, password, attrs)
      attrs['cn'] = "#{attrs['givenName']} #{attrs['sn']}"
      attrs['x-kmc-Lodging'] = attrs['x-kmc-Lodging'] ? 'TRUE' : 'FALSE' # fixme

      Net::LDAP.open_uri(@uri) do |conn|
        dn = Net::LDAP::DN.new('uid', uid, conn.base)

        conn.bind(method: :simple, username: dn, password: password)
        EDITABLE_ATTRS.each do |n|
          conn.replace_attribute(dn, n, attrs[n])
        end
      end
    end

    private

    SEARCH_ATTRS = %w[uid name]

    EDITABLE_ATTRS = %w[
      cn
      sn sn;lang-ja x-kmc-PhoneticSurname
      givenName givenName;lang-ja x-kmc-PhoneticGivenName
      x-kmc-UnivesityDepartment x-kmc-UniversityStatus x-kmc-UniversityMatricYear
      x-kmc-Alias title x-kmc-Generation description
      postalCode postalAddress x-kmc-Lodging
      telephoneNumber
    ]
  end
end

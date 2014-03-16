require 'net/ldap'
require 'net/ldap/dn'
require_relative 'ldap_ext'

module GuildBook
  class UserRepo
    def initialize(uri)
      @uri = uri
    end

    def find(query = nil, active = true)
      filter = Net::LDAP::Filter.present('uid')

      if query
        filter &= SEARCH_ATTRS.collect {|attr| Net::LDAP::Filter.contains(attr, query) }.inject(:|)
      end

      if active
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

      Net::LDAP.open_uri(@uri) do |conn|
        dn = Net::LDAP::DN.new('uid', uid, conn.base)

        conn.bind(method: :simple, username: dn, password: password)
        EDITABLE_ATTRS.each do |n|
          conn.replace_attribute(dn, n, attrs[n])
        end
      end
    end

    private

    SEARCH_ATTRS = %w[
      uid
      sn sn;lang-ja x-kmc-PhoneticSurname
      givenName givenName;lang-ja x-kmc-PhoneticGivenName
    ]

    EDITABLE_ATTRS = %w[
      cn
      sn sn;lang-ja x-kmc-PhoneticSurname
      givenName givenName;lang-ja x-kmc-PhoneticGivenName
      x-kmc-UnivesityDepartment x-kmc-UniversityStatus x-kmc-UniversityMatricYear
      alias title x-kmc-Generation description
      postalCode postalAddress
      mobile homePhone
    ]
  end
end

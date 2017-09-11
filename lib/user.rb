require_relative 'ldap_repo'
require_relative 'date_ext'
require_relative 'string_ext'

module GuildBook
  class UserRepo < LdapRepo
    def search(query = nil, include_inactive = true)
      filter = Net::LDAP::Filter.present('uid')

      if query and (query = query.strip) and !query.empty?
        filter &= SEARCH_ATTRS.collect {|attr| Net::LDAP::Filter.contains(attr, query) }.inject(:|)
      end

      if !include_inactive
        filter &= ~Net::LDAP::Filter.present('shadowExpire')
      end

      return do_search(filter)
    end

    def get(uid)
      do_search(Net::LDAP::Filter.eq('uid', uid)).first or raise Sinatra::NotFound
    end

    def get_many(uids)
      do_search(uids.collect {|uid| Net::LDAP::Filter.eq('uid', uid) }.inject(:|))
    end

    def edit(uid, bind_uid, bind_password, attrs)
      attrs['cn'] = "#{attrs['givenName']} #{attrs['sn']}"
      attrs['x-kmc-Lodging'] = attrs['x-kmc-Lodging'] ? 'TRUE' : 'FALSE' # fixme

      Net::LDAP.open_uri(uri) do |conn|
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
              if !conn.replace_attribute(dn, key, normalize_string(value))
                raise Error, conn.get_operation_result.message
              end
            end
          end
        end

        conn.replace_attribute(dn, 'x-kmc-LastModified', DateTime.now.generalized_time)
      end
    end

    def get_max_uid
      do_search(Net::LDAP::Filter.present('uidNumber'), ['uidNumber']).map {|u| u['uidNumber'].first.to_i }.max
    end

    def get_max_rid
      do_search(Net::LDAP::Filter.present('sambaSID'), ['sambaSID']).map do |e|
        sid_components = e['sambaSID'].first.split /-/
        sid_components.length < 8 ? 0 : sid_components[7].to_i
      end.max
    end

    def add(uid, attributes, bind_uid, bind_password)
      Net::LDAP.open_uri(uri) do |conn|
        dn = Net::LDAP::DN.new('uid', uid, conn.base)
        bind_dn = Net::LDAP::DN.new('uid', bind_uid, conn.base)

        if !conn.bind(method: :simple, username: bind_dn, password: bind_password)
          raise Error, conn.get_operation_result.message
        end

        conn.add(dn: dn, attributes: attributes)
        unless conn.get_operation_result.code == 0 # Success
          raise Error, conn.get_operation_result.message
        end
        conn.replace_attribute(dn, 'x-kmc-LastModified', DateTime.now.generalized_time)
      end
    end

    private

    SEARCH_ATTRS = %w[uid name]

    EDITABLE_ATTRS = %w[
      cn
      sn sshPublicKey x-kmc-PhoneticSurname givenName x-kmc-PhoneticGivenName
      x-kmc-UniversityDepartment x-kmc-UniversityStatus x-kmc-UniversityMatricYear
      x-kmc-Alias title x-kmc-Generation description
      postalCode postalAddress x-kmc-Lodging
      telephoneNumber x-kmc-MailForwardingAddress
    ]

    def normalize_string(s)
      s.to_s.normalize_numbers
    end
  end
end

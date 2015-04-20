require_relative 'ldap_repo'

module GuildBook
  class BaseRepo < LdapRepo
    def get_domain_sid(samba_domain_name)
      do_search(Net::LDAP::Filter.eq('sambaDomainName', samba_domain_name), ['sambaSID']).first['sambaSID'].first
    end
  end
end


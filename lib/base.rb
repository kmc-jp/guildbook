require_relative 'ldap_repo'

module GuildBook
  class BaseRepo < LdapRepo
    def get_kmc_domain_sid
      do_search(Net::LDAP::Filter.eq('sambaDomainName', 'KMC'), ['sambaSID']).first['sambaSID'].first
    end
  end
end


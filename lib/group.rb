require_relative 'ldap_repo'

module GuildBook
  class GroupRepo < LdapRepo
    def get(gid)
      (do_search(Net::LDAP::Filter.eq('cn', gid), ['memberUid']).first or raise Sinatra::NotFound)['memberUid']
    end
  end
end

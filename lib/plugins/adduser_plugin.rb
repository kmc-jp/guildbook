require_relative '../app'
require_relative '../ssha'
require_relative '../base'
require 'smbhash'

module GuildBook
  class App
    get '/!adduser/edit' do
      haml :adduser, locals: {err: nil}
    end

    ## TODO: .lock
    post '/!adduser/add' do
      begin
        uid = params.delete('$uid')
        givenname = params.delete('$givenname')
        surname = params.delete('$surname')
        password = params.delete('$password')
        bind_uid = params.delete('$bind_uid')
        bind_password = params.delete('$bind_password')
        adduser(uid, givenname, surname, password, bind_uid, bind_password)
        redirect absolute_uri(uid)
      rescue
        haml '/!adduser/edit', locals: {err: $!}
      end
    end

    private

    def adduser(uid, givenname, surname, password, bind_uid, bind_password)
      if user_repo.do_search(Net::LDAP::Filter.eq('uid', uid)).first
          raise Error, uid + " already found in LDAP"
      end
      if File.exist?('/home/' + uid)
          raise Error, uid + " already found in /home"
      end
      f = open('/etc/aliases')
      if  f.read.include?(uid)
          raise Error, uid + " already found in /etc/aliases"
      end
      unix_password = Sha1.ssha_hash password
      samba_password = Smbhash.ntlm_hash password
      unix_time = DateTime.now.to_time.to_i
      uid_number = user_repo.get_max_uid + 1
      gid_number = 200 # kmc
      rid_number = user_repo.get_max_rid + 1
      domain_sid = base_repo.get_kmc_domain_sid
      sid = "#{domain_sid}-#{rid_number}"
      attrs = {
        :objectClass => %w{sambaSamAccount inetOrgPerson posixAccount shadowAccount x-kmc-Person},
        :uid => uid,
        :cn => "#{givenname} #{surname}",
        :sn => surname,
        :givenName => givenname,
        :userPassword => unix_password,
        :uidNumber => uid_number.to_s,
        :gidNumber => gid_number.to_s,
        :homeDirectory => "/home/#{uid}",
        :loginShell => '/bin/bash',
        :mail => "#{uid}@kmc.gr.jp",
        :sambaAcctFlags => "[U          ]", # regular user account
        :sambaSID => sid,
        :sambaNTPassword => samba_password,
        :sambaPwdLastSet => unix_time.to_s
      }
      puts attrs
      user_repo.add(uid, attrs, bind_uid, bind_password)
    end

    def base_repo
      BaseRepo.new(settings.ldap_uri['base'])
    end
  end
end

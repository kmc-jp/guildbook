# -*- coding: utf-8 -*-
require_relative '../app'
require_relative '../ssha'
require_relative '../base'
require 'smbhash'

module GuildBook
  class App
    configure do
      @@locker = Mutex.new
    end

    before do
      navlinks << {
        href: absolute_uri('/!adduser'),
        icon: 'user-plus',
        text: 'ユーザ作成',
        order: 20,
      }
    end

    get '/!adduser' do
      haml :adduser, locals: {
        err: nil,
        uid: '',
        givenname: '',
        surname: '',
        bind_uid: remote_user
      }
    end

    post '/!adduser' do
      begin
        uid = params.delete('$uid')
        check_uid_valid(uid)
        check_uid_unique(uid)
        givenname = params.delete('$givenname')
        surname = params.delete('$surname')
        password = params.delete('$password')
        password_confirm = params.delete('$password_confirm')
        bind_uid = params.delete('$bind_uid')
        bind_password = params.delete('$bind_password')
        raise "Password does not match" if password != password_confirm
        check_password_valid(password)
        adduser(uid, givenname, surname, password, bind_uid, bind_password)
        redirect absolute_uri(uid)
      rescue
        haml :adduser, locals: {
          err: $!,
          uid: uid,
          givenname: givenname,
          surname: surname,
          bind_uid: bind_uid
        }
      end
    end

    private

    def adduser(uid, givenname, surname, password, bind_uid, bind_password)
      unix_password = Sha1.ssha_hash password
      samba_password = Smbhash.ntlm_hash password
      unix_time = DateTime.now.to_time.to_i
      gid_number = 200 # kmc
      domain_sid = base_repo.get_domain_sid(samba_domain_name)
      attrs = {
        :objectClass => %w{sambaSamAccount inetOrgPerson posixAccount shadowAccount x-kmc-Person ldapPublicKey},
        :uid => uid,
        :cn => "#{givenname} #{surname}",
        :sn => surname,
        :givenName => givenname,
        :userPassword => unix_password,
        :gidNumber => gid_number.to_s,
        :homeDirectory => "/home/#{uid}",
        :loginShell => '/bin/bash',
        :mail => "#{uid}@kmc.gr.jp",
        :sambaAcctFlags => "[U          ]", # regular user account
        :sambaNTPassword => samba_password,
        :sambaPwdLastSet => unix_time.to_s
      }
      @@locker.synchronize do
        uid_number = user_repo.get_max_uid + 1
        rid_number = user_repo.get_max_rid + 1
        attrs[:uidNumber] = uid_number.to_s
        attrs[:sambaSID] = "#{domain_sid}-#{rid_number}"
        puts attrs
        user_repo.add(uid, attrs, bind_uid, bind_password)
      end
    end

    def base_repo
      BaseRepo.new(settings.ldap_uri['base'])
    end

    def samba_domain_name
      settings.samba_domain_name
    end

    def check_password_valid(password)
      if (/\A[\x20-\x7e]+\z/.match(password).nil?)
        raise UserRepo::Error, "Your password contains invalid letters"
      end
      if (/\A[\x20-\x7e]{8,}\z/.match(password).nil?)
        raise UserRepo::Error, "Your password is too short. You need at least 8 letters."
      end

      kinds = (/[a-z]/.match(password).nil? ? 0 : 1) +
        (/[A-Z]/.match(password).nil? ? 0 : 1) +
        (/[0-9]/.match(password).nil? ? 0 : 1) +
        (/[^a-zA-Z0-9]/.match(password).nil? ? 0 : 1)
      if (kinds < 3)
        raise UserRepo::Error, "Your password should contain at least three of lower letters, upper letters, numbers and symbols"
      end
    end

    def check_uid_valid(uid)
      unless (Range.new(3, 8) === uid.length)
        raise UserRepo::Error, "Your login name should consist of at least 3 characters in length and at most 8."
      end
      if (/\A[a-z][a-z0-9]{2,7}\z/.match(uid).nil?)
        raise UserRepo::Error, "Your login name should consist of alphanumeric characters."
      end
    end

    def check_uid_unique(uid)
      blacklist = settings.adduser['login_blacklist'].flatten
      if blacklist.include?(uid)
        raise UserRepo::Error, "Login name '#{uid}' is blacklisted"
      end

      if File.exist?(File.join('/home', uid))
        raise UserRepo::Error, "Login name '#{uid}' found in /home"
      end

      if user_repo.do_search(Net::LDAP::Filter.eq('uid', uid)).first
        raise UserRepo::Error, "Login name '#{uid}' found in LDAP"
      end
    end
  end
end

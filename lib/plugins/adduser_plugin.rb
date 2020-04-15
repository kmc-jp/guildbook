# -*- coding: utf-8 -*-
require 'sinatra/json'
require 'smbhash'

require_relative '../app'
require_relative '../ssha'
require_relative '../base'

module GuildBook
  class App
    class PasswordRestrictionError < StandardError; end
    class UidRestrictionError < StandardError; end

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
        error: nil,
        uid: '',
        givenname: '',
        surname: '',
        bind_uid: remote_user
      }
    end

    post '/!adduser/checkuid' do
      result =
        begin
          uid = params.delete('value')
          check_uid_valid(uid)
          check_uid_unique(uid)

          {ok: true, value: uid}
        rescue UidRestrictionError => e
          {ok: false, value: uid, message: e.message}
        end

      cache_control :no_store
      json result
    end

    post '/!adduser' do
      begin
        uid = params.delete('uid')
        check_uid_valid(uid)
        check_uid_unique(uid)
        givenname = params.delete('givenname')
        surname = params.delete('surname')
        password = params.delete('password')
        password_confirm = params.delete('password_confirm')
        bind_uid = params.delete('$bind_uid')
        bind_password = params.delete('$bind_password')
        raise "Password does not match" if password != password_confirm
        check_password_valid(password)
        adduser(uid, givenname, surname, password, bind_uid, bind_password)
        redirect absolute_uri(uid)
      rescue
        haml :adduser, locals: {
          error: $!,
          uid: uid,
          givenname: givenname,
          surname: surname,
          bind_uid: bind_uid
        }
      end
    end

    get '/!passwd/:uid' do
      haml :passwd, locals: {
        error: nil,
        uid: params[:uid],
        bind_uid: remote_user,
      }
    end

    post '/!passwd/:uid' do
      begin
        uid = params.delete('uid')
        password = params.delete('password')
        password_confirm = params.delete('password_confirm')
        bind_uid = params.delete('$bind_uid')
        bind_password = params.delete('$bind_password')
        raise "Password does not match" if password != password_confirm
        check_password_valid(password)
        chpasswd(uid, bind_uid, bind_password, password)
        redirect absolute_uri(uid)
      rescue
        haml :passwd, locals: {
          error: $!.inspect,
          uid: uid,
          bind_uid: remote_user,
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
        user_repo.add(uid, attrs, bind_uid, bind_password)
      end
    end

    def chpasswd(uid, bind_uid, bind_password, password)
      unix_password = Sha1.ssha_hash password
      samba_password = Smbhash.ntlm_hash password
      unix_time = DateTime.now.to_time.to_i

      attrs = {
        :userPassword => unix_password,
        :sambaNTPassword => samba_password,
        :sambaPwdLastSet => unix_time.to_s
      }

      user_repo.edit(uid, bind_uid, bind_password, attrs, update_last_modified: false)
    end

    def base_repo
      BaseRepo.new(settings.ldap_uri['base'])
    end

    def samba_domain_name
      settings.samba_domain_name
    end

    def check_password_valid(password)
      unless /\A[\x20-\x7e]+\z/.match?(password)
        raise PasswordRestrictionError, "Your password contains invalid letters"
      end
      if password.length < 8
        raise PasswordRestrictionError, "Your password is too short. You need at least 8 letters."
      end

      kinds = (/[a-z]/.match?(password) ? 1 : 0) +
        (/[A-Z]/.match?(password) ? 1 : 0) +
        (/[0-9]/.match?(password) ? 1 : 0) +
        (/[^a-zA-Z0-9]/.match?(password) ? 1 : 0)
      if kinds < 3
        raise PasswordRestrictionError, "Your password should contain at least three of lower letters, upper letters, numbers and symbols"
      end
    end

    def check_uid_valid(uid)
      unless (3..8) === uid.length
        raise UidRestrictionError, "Your login name should consist of at least 3 characters in length and at most 8."
      end

      unless /\A[a-z][a-z0-9]{2,7}\z/.match?(uid)
        raise UidRestrictionError, "Your login name should consist of alphanumeric characters."
      end
    end

    def check_uid_unique(uid)
      blacklist = settings.adduser['login_blacklist'].flatten
      if blacklist.include?(uid)
        raise UidRestrictionError, "Login name '#{uid}' is blacklisted"
      end

      if File.exist?(File.join('/home', uid))
        raise UidRestrictionError, "Login name '#{uid}' found in /home"
      end

      if user_repo.do_search(Net::LDAP::Filter.eq('uid', uid)).first
        raise UidRestrictionError, "Login name '#{uid}' found in LDAP"
      end
    end
  end
end

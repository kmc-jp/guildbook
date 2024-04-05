require_relative './md4'

module NtlmHash
  def self.ntlm_hash(passwd)
    passwd = passwd.encode('UTF-16LE')
    MD4.hexdigest(passwd).upcase
  end
end

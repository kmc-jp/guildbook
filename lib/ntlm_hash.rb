require 'openssl'

module NtlmHash
  def self.ntlm_hash(passwd)
    passwd = passwd.encode('UTF-16LE')
    OpenSSL::Digest::MD4.hexdigest(passwd).upcase
  end
end

require 'uri'
require 'net/ldap'

class Net::LDAP::Entry
  def fix_encoding!
    each do |n, v|
      v.each do |s|
        s.force_encoding('UTF-8')
      end
    end
    self
  end
end

class Net::LDAP
  def self.open_uri(uri, opt = {}, &block)
    uri = URI.parse(uri.to_s) unless uri.kind_of?(URI)

    unless uri.kind_of?(URI::LDAP)
      raise URI::BadURIError.new('Specified URI is not an LDAP URI')
    end

    opt = {
      host: uri.host,
      port: uri.port,
      base: uri.dn,
      # Net:LDAP does NOT support the option {:encryption => :plaintext};
      # the following is workaround for non-TLS connection.
      encryption: uri.kind_of?(URI::LDAPS) ? :simple_tls : nil
    }.merge(opt)

    open(opt, &block)
  end
end

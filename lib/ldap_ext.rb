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
    uri = URI.parse(uri) unless uri.is_a?(URI)

    opt = {
      host: uri.host,
      port: uri.port,
      base: uri.dn,
      encryption: uri.is_a?(URI::LDAPS) ? :simple_tls : :plaintext
    }.merge(opt)

    open(opt, &block)
  end
end

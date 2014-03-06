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

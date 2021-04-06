# Workaround for https://github.com/krissi/ruby-smbhash/blob/master/lib/smbhash.rb#L37-L46
module Smbhash
  RUBY_VERSION = '2.999999999'
  require 'smbhash'
  remove_const :RUBY_VERSION
end

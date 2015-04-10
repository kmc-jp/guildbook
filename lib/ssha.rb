
require 'digest/sha1'

module Sha1
  module_function
  def ssha_hash(password)
    salt_charset = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    salt = salt_charset[rand 64] + salt_charset[rand 64]
    '{SSHA}' + Base64.encode64(Digest::SHA1.digest(password + salt) + salt).chomp
  end
end


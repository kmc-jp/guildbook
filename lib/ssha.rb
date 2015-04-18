
require 'securerandom'
require 'digest/sha1'

module Sha1
  module_function
  def ssha_hash(password)
    salt_charset = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    salt = Array.new(4) { salt_charset[SecureRandom.random_number(salt_charset.length)] }.join
    '{SSHA}' + Base64.encode64(Digest::SHA1.digest(password + salt) + salt).chomp
  end
end


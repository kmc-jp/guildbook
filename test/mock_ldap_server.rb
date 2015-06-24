require 'forwardable'
require 'minitest/mock'
require 'ldap/server'

class MockLdapServer < LDAP::Server
  class Operation < LDAP::Server::Operation
    extend Forwardable
    def_delegators :@mock, :simple_bind, :search, :modify, :add, :del, :modifydn, :compare

    def initialize(connection, messageID, mock)
      super(connection, messageID)
      @mock = mock
    end

    def simple_bind(*args)
      result = @mock.simple_bind(*args)
      raise result if result.is_a?(LDAP::ResultError)
    end

    def search(*args)
      result = @mock.search(*args)
      raise result if result.is_a?(LDAP::ResultError)
      raise LDAP::ResultError::NoSuchObject if !result or result.empty?
      result.each do |entry|
        dn = entry.delete('dn').first
        send_SearchResultEntry(dn, entry)
      end
    end

    def add(*args)
      result = @mock.add(*args)
      raise result if result.is_a?(LDAP::ResultError)
    end

    def del(*args)
      result = @mock.del(*args)
      raise result if result.is_a?(LDAP::ResultError)
    end

    def modifydn(*args)
      result = @mock.modifydn(*args)
      raise result if result.is_a?(LDAP::ResultError)
    end

    def compare(*args)
      result = @mock.compare(*args)
      raise result if result.is_a?(LDAP::ResultError)
      return !!result
    end
  end

  attr_reader :mock

  def initialize(opt = {})
    @mock = Minitest::Mock.new

    opt = {
      bindaddr: '127.0.0.1',
      operation_class: Operation,
      operation_args: @mock
    }.merge(opt)

    super(opt)
  end
end

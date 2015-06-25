require 'test_helper'

class LdapRepoTest < Minitest::Test
  PORT = 33899

  def setup
    @server = MockLdapServer.new(port: PORT)
    @server.run_tcpserver
  end

  def teardown
    @server.stop
  end

  def test_do_search
    entries = [{'dn' => ['cn=alice,dc=example,dc=com'], 'cn' => ['alice']},
               {'dn' => ['cn=bob,dc=example,dc=com'], 'cn' => ['bob']}]

    @server.mock.expect(:simple_bind, nil, [3, nil, ''])
    @server.mock.expect(:search, entries,
                        ['dc=example,dc=com', LDAP::Server::WholeSubtree,
                         LDAP::Server::NeverDerefAliases, [:present, 'cn']])

    repo = GuildBook::LdapRepo.new("ldap://127.0.0.1:#{PORT}/dc=example,dc=com")
    result = repo.do_search(Net::LDAP::Filter.present('cn'))
    assert_equal 2, result.size
    assert_equal 'alice', result[0][:cn].first

    @server.mock.verify
  end
end

ENV['RACK_ENV'] = 'test'
ENV['APP_ENV'] = 'test'

require 'capybara/rspec'
require 'net/ldap'
require 'net/ldap/dataset'
require 'open3'
require 'yaml'

compose_file = File.expand_path('compose.yml', __dir__)
address, error, status = Open3.capture3('docker', 'compose', '-f', compose_file, 'port', 'ldap', '389')
raise "Cannot discover integration LDAP port: #{error}" unless status.success?
ldap_port = Integer(address.strip.rpartition(':').last)

# Load the deployed Rack entry point, including every plugin.
Capybara.app = Rack::Builder.parse_file(File.expand_path('../../config.ru', __dir__)).first
Capybara.default_driver = :rack_test

# Never use the developer's LDAP settings, even when running against local config.
config = YAML.load_file(File.expand_path('../../config/guildbook.yml.example', __dir__)).fetch('development')
config['ldap_uri'] = %w[base users groups].to_h do |name|
  dn = name == 'base' ? 'dc=example,dc=test' : "ou=#{name},dc=example,dc=test"
  [name, "ldap://127.0.0.1:#{ldap_port}/#{dn}"]
end
config.each { |key, value| GuildBook::App.set(key, value) }
GuildBook::App.set :raise_errors, true
GuildBook::App.set :show_exceptions, false

RSpec.configure do |rspec|
  rspec.before(:each, type: :feature) do
    # Restore fixtures for independent, repeatable tests, including LDAP writes.
    ldap = Net::LDAP.new(
      host: '127.0.0.1', port: ldap_port,
      auth: {method: :simple, username: 'cn=admin,dc=example,dc=test', password: 'integration-admin'}
    )
    unless ldap.bind
      raise "Cannot bind to integration-test LDAP: #{ldap.get_operation_result.message}"
    end

    entries = File.open(File.expand_path('ldap/entries.ldif', __dir__)) do |file|
      Net::LDAP::Dataset.read_ldif(file)
    end
    entries.keys.reverse_each do |dn|
      unless ldap.delete(dn: dn) || ldap.get_operation_result.code == 32
        raise "Cannot delete #{dn}: #{ldap.get_operation_result.message}"
      end
    end
    entries.each do |dn, attributes|
      unless ldap.add(dn: dn, attributes: attributes)
        raise "Cannot seed #{dn}: #{ldap.get_operation_result.message}"
      end
    end
  end
end

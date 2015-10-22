require_relative 'boot'

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Guildbook
  class Application < Rails::Application
    config.time_zone = 'Asia/Tokyo'
    config.i18n.default_locale = :ja
  end
end

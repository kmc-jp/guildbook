require_relative '../app'
require_relative 'users_json_helpers'
require "sinatra/json"

module GuildBook
  class App
    get '/users.json' do
      users = user_repo.search(nil, false).sort_by {|u| u['uidNumber'].first }
      json users
    end
  end
end

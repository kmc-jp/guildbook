require_relative '../app'
require_relative 'univ_helpers'

module GuildBook
  class App
    get '/!univ' do
      users = user_repo.search(nil, false).sort_by {|u| u['uidNumber'].first }
      haml :univ, locals: {users: users}, layout: false
    end
  end
end

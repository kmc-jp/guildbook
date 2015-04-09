require_relative '../app'
require_relative 'univ_helpers'

module GuildBook
  class App
    get '/!univ' do
      all_users = user_repo.search(nil, false).sort_by {|u| u['uidNumber'].first }
      outdated_users, active_users = all_users.partition {|u| GuildBook::UnivHelper.outdated?(u) }
      users = active_users.to_a + outdated_users.to_a
      haml :univ, locals: {users: users}, layout: false
    end
  end
end

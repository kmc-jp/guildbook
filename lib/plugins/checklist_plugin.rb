require_relative '../app'
require_relative 'checklist_helpers'

module GuildBook
  class App
    get '/!checklist' do
      users = user_repo.search(nil, false).sort_by {|u| u['uidNumber'].first }
      haml :checklist, locals: {users: users, columns: (params['columns'] || '').gsub(',', '|')}, layout: false
    end
  end
end

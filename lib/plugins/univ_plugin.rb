require_relative '../app'
require_relative 'univ_helpers'

module GuildBook
  class App
    get '/!univ' do
      haml :univauth, locals: {error: nil}
    end
    
    post '/!univ' do
      bind_uid = params.delete('$bind_uid')
      bind_password = params.delete('$bind_password')
      if params['action'] == 'auth'
        begin
          all_users = user_repo.search_auth( bind_uid, bind_password, nil, false).sort_by {|u| u['uidNumber'].first.to_i }
          outdated_users, active_users = all_users.partition {|u| GuildBook::UnivHelper.outdated?(u) }
          users = active_users.to_a + outdated_users.to_a
          haml :univ, locals: {users: users}, layout: false
        rescue
          user = user_repo.get(bind_uid)
          params.each do |k, v|
            user[k] = [v]
          end
          haml :univauth, locals: {error: $!}
        end
      end
    end
  end
end

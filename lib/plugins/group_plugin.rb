require_relative '../app'
require_relative '../group'

module GuildBook
  class App
    get '/!group/:group' do |group|
      sort_keys = [params['sort'], settings.ui['default_sort_keys']].compact.flat_map(&Utils.method(:parse_sortkeys))

      users = user_repo.get_many(group_repo.get(group)).sort do |u, v|
        sort_keys.inject(0) do |x, (key, ord)|
          x.nonzero? || (u[key] <=> v[key]) * ord
        end
      end

      haml :index, locals: {users: users}
    end

    private

    def group_repo
      GroupRepo.new(settings.ldap_uri['groups'])
    end
  end
end

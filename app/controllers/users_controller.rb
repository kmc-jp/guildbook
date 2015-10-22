require_relative '../../lib/utils'
require_relative '../../lib/user'

class UsersController < ApplicationController
  def index
    sort_keys = [params['sort'], Settings.ui.default_sort_keys].compact.flat_map(&::GuildBook::Utils.method(:parse_sortkeys))

    @users = user_repo.search(params['q'], params['all']).sort do |u, v|
      sort_keys.inject(0) do |x, (key, ord)|
        x.nonzero? || (u[key].map(&GuildBook::Utils.method(:tokenize)) <=> v[key].map(&GuildBook::Utils.method(:tokenize))) * ord
      end
    end
  end

  def show
    @user = user_repo.get(params[:id])
  end

  def edit
    @user = user_repo.get(params[:id])
  end

  private

  def user_repo
    ::GuildBook::UserRepo.new(Settings.ldap_uri.users)
  end
end

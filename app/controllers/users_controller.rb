class UsersController < ApplicationController
  def index
    @users = sort(User.all)
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  private

  def sort(users, sort_keys = nil)
    sort_keys = [*sort_keys, Settings.ui.default_sort_keys].compact.flat_map(&method(:parse_sortkeys))

    users.sort do |u, v|
      sort_keys.inject(0) do |x, (key, ord)|
        x.nonzero? || (u[key, true].map(&method(:tokenize)) <=> v[key, true].map(&method(:tokenize))) * ord
      end
    end
  end

  def parse_sortkeys(s)
    s.split(',').map {|key| key[0] != '-' ? [key, 1] : [key[1..-1], -1] }
  end

  def tokenize(s)
    s.to_s.split(/(\d+)|\s+/).map {|t| t =~ /\A\d+\z/ ? t.to_i : t }
  end
end

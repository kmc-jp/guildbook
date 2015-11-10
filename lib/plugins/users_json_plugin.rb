require_relative '../app'
require_relative 'users_json_helpers'
require "sinatra/json"
require "json"

module GuildBook
  class App
    get '/users.json' do
      only = params.empty? || params[:only].nil? ? [] : params[:only].split(',')
      if !params.empty? && !params[:filter].nil?
        filter = params[:filter].gsub(" ", "")
        filter = params[:filter].split(",").map{|item|
          t = item.split('=')
          k = t[0]
          v = t[1]
          case k
          when "username"
            ["uid", v]
          else
            [k, v]
          end
        }
        p filter
        repo = user_repo.filter(filter)
      else
        repo = user_repo.search(nil, false)
      end
      users = repo.sort_by {|u| u['uidNumber'].first }.map{|u|
        data = {
          username: GuildBook::UsersJsonHelper.uid(u),
          title: GuildBook::UsersJsonHelper.title(u),
          kyotou_student: !!GuildBook::UsersJsonHelper.kyotou_student?(u),
          kyotou_grade: GuildBook::UsersJsonHelper.kyotou_grade(u),
          real_name: GuildBook::UsersJsonHelper.name(u),
          kana: GuildBook::UsersJsonHelper.yomi(u),
          address: GuildBook::UsersJsonHelper.address(u),
          tel: GuildBook::UsersJsonHelper.tel(u),
          email: GuildBook::UsersJsonHelper.email(u),
        }
        if only.count == 0
          data
        else
          res = {}
          only.select{|o| data[o.intern] }.each{|o| res[o] = data[o.intern]}
          res
        end
      }
      json users
    end
  end
end

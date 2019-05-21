# -*- coding: utf-8 -*-
require_relative '../app'

module GuildBook
  class App
    before do
      navlinks << {
        href: absolute_uri('/!help'),
        icon: 'question-circle',
        text: '使い方'
      }
    end

    get '/!help' do
      redirect settings.help_uri
    end
  end
end

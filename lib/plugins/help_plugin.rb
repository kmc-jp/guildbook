# -*- coding: utf-8 -*-
require_relative '../app'

module GuildBook
  class App
    before do
      navlinks << {
        href: '/!help',
        icon: 'question-sign',
        text: '使い方'
      }
    end

    get '/!help' do
      redirect settings.help_uri
    end
  end
end

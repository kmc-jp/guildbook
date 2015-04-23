# -*- coding: utf-8 -*-
require_relative '../app'

module GuildBook
  class App
    before do
      navlinks << {
        href: settings.help_uri,
        icon: 'question-sign',
        text: '使い方'
      }
    end
  end
end

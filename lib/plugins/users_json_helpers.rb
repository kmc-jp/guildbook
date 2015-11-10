# -*- coding: utf-8 -*-
require 'date'
require_relative '../date_ext'

module GuildBook
  module UsersJsonHelper
    class << self
      def initiate?(u)
        u['x-kmc-Generation'].first.to_i == Date.today.academic_year - 1976 rescue false
      end

      def student?(u)
        status = u['x-kmc-UniversityStatus'].first
        status and status =~/^[BMD]?\d+$/
      end

      def parse_grade(g)
        return [:u, $1.to_i] if g =~ /^B?(\d+)$/
        return [:m, $1.to_i] if g =~ /^M(\d+)$/
        return [:d, $1.to_i] if g =~ /^D(\d+)$/
        return [:o, 0]
      end

      def machine_grade(u)
        parse_grade(u['x-kmc-UniversityStatus'].first || '')
      end

      def pipes(cols)
        '|' * cols.count('|')
      end
    end
  end
end

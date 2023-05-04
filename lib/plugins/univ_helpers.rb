# -*- coding: utf-8 -*-
require 'date'

module GuildBook
  module UnivHelper
    class << self
      def executive?(u)
        ['会長', '副会長', '代表', '会計'].include?(u['title'].first)
      end

      def uid(u)
        u['uid'].first || ''
      end

      def title(u)
        u['title'].first || ''
      end

      def kyotou_student?(u)
        status = u['x-kmc-UniversityStatus'].first
        department = u['x-kmc-UniversityDepartment'].first
        status and department and status =~/^[BMD]?\d+$/ and department.gsub(/(?<=大学)[[:space:]]*大学院/, '') !~ /(?<!京都)大学|高等学校|中学/  # FIXME
      end

      def kyotou_department(u)
        case u['x-kmc-UniversityDepartment'].first
        when nil
          ''
        when /\A(?:京都大学[[:space:]]*(?:大学院[[:space:]]*)?)?(.*(?:学部|研究科|研究所|センター))/
          $1
        end
      end

      def kyotou_grade(u)
        (u['x-kmc-UniversityStatus'].first || '').sub(/\AB/, '')
      end
      
      def kyotou_student_number(u)
        u['x-kmc-KUStudentNumber'].first || ''
      end

      def name(u)
        "#{u['sn;lang-ja'].first} #{u['givenName;lang-ja'].first}"
      end

      def yomi(u)
        "#{u['x-kmc-PhoneticSurname'].first} #{u['x-kmc-PhoneticGivenName'].first}"
      end

      def lodging(u)
        u['x-kmc-Lodging'].first == 'FALSE' ? '自宅' : '下宿'
      end

      def address(u)
        u['postalAddress'].first || ''
      end

      def tel(u)
        u['telephoneNumber'].first || ''
      end

      def mailto_email(u)
        return '' unless u['mail'].first
        "mailto:#{u['mail'].first}"
      end

      def email(u)
        u['mail'].first || ''
      end

      def outdated?(u)
        today = Date.today
        lm = u['x-kmc-LastModified'].first
        !lm or Date.parse(lm) < Date.new(today.month >=4 ? today.year : today.year - 1, 4, 1)
      end
    end
  end
end

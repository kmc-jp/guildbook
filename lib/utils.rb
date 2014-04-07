module GuildBook
  module Utils
    class << self
      def parse_sortkeys(s)
        s.split(',').map {|key| key[0] != '-' ? [key, 1] : [key[1..-1], -1] }
      end
    end
  end
end

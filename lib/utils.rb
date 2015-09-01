module GuildBook
  module Utils
    class << self
      def parse_sortkeys(s)
        s.split(',').map {|key| key[0] != '-' ? [key, 1] : [key[1..-1], -1] }
      end

      def tokenize(s)
        s.split(/(\d+)|\s+/).map {|t| t =~ /\A\d+\z/ ? t.to_i : t }
      end
    end
  end
end

# https://www.rfc-editor.org/rfc/rfc1320

module MD4
  module FixedArith
    MASK32 = (1 << 32) - 1

    refine Integer do
      def rol32(bits)
        bits %= 32
        (self << bits) & MASK32 | ((self & MASK32) >> (32 - bits))
      end

      def add32(other)
        (self + other) & MASK32
      end
    end
  end

  using FixedArith

  def self.digest(s)
    f = ->(x, y, z) { x & y | ~x & z }
    g = ->(x, y, z) { x & y | x & z | y & z }
    h = ->(x, y, z) { x ^ y ^ z }

    s = s.b + ?\x80.b + ?\x00.b * (64 - (s.bytesize + 1 + 8) % 64) + [s.bytesize * 8].pack('Q<')
    a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

    (0 ... s.bytesize).step(64) do |offset|
      x = s.unpack('V16', offset: offset)
      aa, bb, cc, dd = a, b, c, d

      [0, 4, 8, 12].each do |k|
        a = (a + f.(b, c, d) + x[k   ]).rol32( 3)
        d = (d + f.(a, b, c) + x[k+ 1]).rol32( 7)
        c = (c + f.(d, a, b) + x[k+ 2]).rol32(11)
        b = (b + f.(c, d, a) + x[k+ 3]).rol32(19)
      end
      [0, 1, 2, 3].each do |k|
        a = (a + g.(b, c, d) + x[k   ] + 0x5a827999).rol32( 3)
        d = (d + g.(a, b, c) + x[k+ 4] + 0x5a827999).rol32( 5)
        c = (c + g.(d, a, b) + x[k+ 8] + 0x5a827999).rol32( 9)
        b = (b + g.(c, d, a) + x[k+12] + 0x5a827999).rol32(13)
      end
      [0, 2, 1, 3].each do |k|
        a = (a + h.(b, c, d) + x[k   ] + 0x6ed9eba1).rol32( 3)
        d = (d + h.(a, b, c) + x[k+ 8] + 0x6ed9eba1).rol32( 9)
        c = (c + h.(d, a, b) + x[k+ 4] + 0x6ed9eba1).rol32(11)
        b = (b + h.(c, d, a) + x[k+12] + 0x6ed9eba1).rol32(15)
      end
      a, b, c, d = a.add32(aa), b.add32(bb), c.add32(cc), d.add32(dd)
    end

    [a, b, c, d].pack('V4')
  end

  def self.hexdigest(s)
    digest(s).unpack1('H*')
  end
end

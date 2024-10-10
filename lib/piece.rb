ABBREVIATIONS = {
  'king' => :K,
  'queen' => :Q,
  'rook' => :R,
  'knight' => :N,
  'bishop' => :B,
  'pawn' => :""
}.freeze

WHITE_SYMBOLS = {
  K: 0x2654,
  Q: 0x2655,
  R: 0x2656,
  N: 0x2658,
  B: 0x2657,
  "": 0x2659
}

BLACK_SYMBOLS = {
  K: 0x265A,
  Q: 0x265B,
  R: 0x265C,
  N: 0x265E,
  B: 0x265D,
  "": 0x265F
}

COLORS = %i[white black].freeze

class Piece
  attr_accessor :name, :abbr, :color, :symbol

  def initialize(name, color)
    @name = name
    @color = color
    @abbr = abbreviate(name)
    @symbol = make_symbols(abbr, color)
  end

  def to_s
    @symbol
  end

  private

  def abbreviate(name)
    ABBREVIATIONS[name]
  end

  def make_symbols(abbr, color)
    symbols_h = color == :white ? WHITE_SYMBOLS : BLACK_SYMBOLS
    symbols_h[abbr].chr(Encoding::UTF_8)
  end
end

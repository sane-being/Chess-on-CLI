module PiecesSet
  ABBREVIATIONS = {
    'king' => :K,
    'queen' => :Q,
    'rook' => :R,
    'knight' => :N,
    'bishop' => :B,
    'pawn' => :""
  }.freeze

  COLORS = %i[white black].freeze

  def abbreviate(name)
    ABBREVIATIONS[name]
  end
end

class Piece
  include PiecesSet
  attr_accessor :name, :abbr, :color, :pos

  def initialize(name, color, pos)
    @name = name
    @abbr = abbreviate(name)
    @color = color
  end

  def to_s
    "#{color} #{name}"
  end
end

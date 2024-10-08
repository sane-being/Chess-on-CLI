require_relative 'string'

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

  COLUMNS = ('a'..'h').to_a
  ROWS = (1..8).to_a

  def abbreviate(name)
    ABBREVIATIONS[name]
  end

  def possible_moves(piece, current_pos)
    current_pos in [col_s, row]
    col = col_s.ord - 96

    case piece.abbr
    when :K
      temp_col = ((col - 1)..(col + 1)).to_a
      temp_row = ((row - 1)..(row + 1)).to_a
      moves = temp_col.product(temp_row) - current_pos
    when :Q # cross not implemented rowet
      moves = [col].product((1..8).to_a) +
              (1..8).to_a.product([row])
      moves += (1..8).to_a.product((row - col + 1)..(row - col + 8)) +
               ((col - row + 1)..(col - row + 8)).product((1..8).to_a)
    when :R
      moves = [col].product((1..8).to_a) +
              (1..8).to_a.product([row])
    when :N
      moves = [col + 2, col - 2].product([row + 1, row - 1]) +
              [col + 1, col - 1].product([row + 2, row - 2])
    when :B
      moves = (1..8).to_a.product((row - col + 1)..(row - col + 8)) +
              ((col - row + 1)..(col - row + 8)).product((1..8).to_a)
    when :""
      i = piece.color == :white ? 1 : -1
      moves = ((col - 1)..(col + 1)).to_a.product([row + i])
    end

    moves.select! { |square| square.all? { |num| (1..8).include? num } }
    moves.map { |square| square[0] = (square[0] + 96).chr }
  end
end

class Piece
  include PiecesSet
  attr_accessor :name, :abbr, :color

  def initialize(name, color)
    @name = name
    @abbr = abbreviate(name)
    @color = color
  end

  def to_s
    "#{color} #{name}"
  end
end

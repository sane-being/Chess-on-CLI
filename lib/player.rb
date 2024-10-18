require_relative 'piece'

# Player object
class Player
  SEQ_OF_PIECES = %w[rook knight bishop queen king bishop knight rook].freeze

  attr_accessor :color, :attack_map, :king

  def initialize(color)
    @color = color
    # Hash of all the pieces (16) of player,
    # piece => squares attackable by it on next move
    @attack_map = create_empty_attack_map(color)
  end

  def to_s
    color.to_s
  end

  private

  def create_empty_attack_map(color)
    pawn_row, pieces_row = case color
                           when :white then [2, 1]
                           when :black then [7, 8]
                           end
    pieces_a = create_pieces(pawn_row, pieces_row)
    pieces_a.to_h { |piece| [piece, nil] }
  end

  def create_pieces(pawn_row, pieces_row)
    pieces_a = []

    SEQ_OF_PIECES.each_with_index do |piece_name, i|
      col = i + 1 # index starts from 0, but col should start from 1
      pawn = Piece.new('pawn', color, [col, pawn_row])
      piece = Piece.new(piece_name, color, [col, pieces_row])
      @king = piece if piece_name == 'king'

      pieces_a.push pawn, piece
    end

    pieces_a
  end
end

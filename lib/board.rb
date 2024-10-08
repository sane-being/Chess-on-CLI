require_relative 'piece', 'possible_moves'

class Board
  include PossibleMoves
  attr_accessor :current_state

  def initialize
    # board hash of 64 squares, square => occupying piece ('' if empty)
    @current_state = create_new_board
  end

  private

  def create_new_board
    ## Array of 64 squares: ['a',1] to ['h',8]
    new_board = ('a'..'h').to_a.product((1..8).to_a)
    # creating empty Board hash,
    new_board = new_board.to_h { |square| [square, ''] }

    # placing pawns
    ('a'..'h').each do |col|
      new_board[[col, 2]] = Piece.new('pawn', :white)
      new_board[[col, 7]] = Piece.new('pawn', :black)
    end

    # placing remaining pieces
    col_of_pieces = {
      'a' => 'rook',
      'b' => 'knight',
      'c' => 'bishop',
      'd' => 'queen',
      'e' => 'king',
      'f' => 'bishop',
      'g' => 'knight',
      'h' => 'rook'
    }
    col_of_pieces.each do |col, piece|
      new_board[[col, 1]] = Piece.new(piece, :white)
      new_board[[col, 8]] = Piece.new(piece, :black)
    end

    new_board # returning board
  end

  def to_s
    current_state
  end
end

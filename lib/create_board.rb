require_relative 'piece'

module CreateNewBoard
  attr_accessor :white_king, :black_king

  def create_board
    ## Array of 64 squares: [1,1] to [8,8]
    new_board_a = []
    (1..8).to_a.reverse.each { |row| new_board_a += (1..8).to_a.product([row]) }
    new_board_a
  end

  def create_pieces
    pieces_a = []
    create_pawns(pieces_a)
    create_other_pieces(pieces_a)
    pieces_a
  end

  def create_pawns(pieces_a)
    # creating pawns
    (1..8).each do |col|
      pieces_a.push Piece.new('pawn', :white, [col, 2])
      pieces_a.push Piece.new('pawn', :black, [col, 7])
    end
  end

  def create_other_pieces(pieces_a)
    # creating remaining pieces
    pieces_seq = %w[rook knight bishop queen king bishop knight rook]
    pieces_seq.each_with_index do |piece_name, col|
      # index starts from 0, but col should start from 1
      if piece_name == 'king'
        @white_king = Piece.new(piece_name, :white, [col + 1, 1])
        @black_king = Piece.new(piece_name, :black, [col + 1, 8])
        pieces_a.push(@white_king)
        pieces_a.push(@black_king)
      else
        pieces_a.push Piece.new(piece_name, :white, [col + 1, 1])
        pieces_a.push Piece.new(piece_name, :black, [col + 1, 8])
      end
    end
  end
end

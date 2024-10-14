require_relative 'piece'

module CreateBoard
  def create_new_board
    ## Array of 64 squares: [1,1] to [8,8]
    new_board = []
    (1..8).to_a.reverse.each { |row| new_board += (1..8).to_a.product([row]) }
    # creating empty Board hash,
    new_board.to_h { |square| [square, nil] }
  end

  def create_pieces
    pieces_a = []

    # creating pawns
    (1..8).each do |col|
      pieces_a.push Piece.new('pawn', :white, [col, 2])
      pieces_a.push Piece.new('pawn', :black, [col, 7])
    end

    # creating remaining pieces
    pieces_seq = %w[rook knight bishop queen king bishop knight rook]
    pieces_seq.each_with_index do |piece_name, col|
      col += 1 # index starts from 0, but col should start from 1
      pieces_a.push Piece.new(piece_name, :white, [col, 1])
      pieces_a.push Piece.new(piece_name, :black, [col, 8])
    end

    puts 'pieces created'

    pieces_hash = {}

    pieces_a.each do |piece|
      # placing pieces on the board (@board_h)
      puts "#{piece.square}, #{piece}"
      @board_h.store(piece.square, piece)
      # finding squares that the piece can attack on the next move
      pieces_hash.store(piece, attacks(piece))
      puts 'Seems ok'
    end

    pieces_hash
  end
end

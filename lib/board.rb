require_relative 'piece'

class Board
  attr_accessor :board_h, :turn_of

  def initialize
    # board hash of 64 squares, square => occupying piece ('' if empty)
    @board_h = create_new_board
    @turn_of = :white
    @moves_a = []
  end

  def play
    move = gets
    decode_move(move) in [square_from, square_to]
    move = make_move(square_from, square_to)
    @moves_a.push(move)
    turn_of = turn_of == :white ? :black : :white
  end

  def decode_move(move)
    move = move.split
    square_from, square_to = move[0..1], move[2..3] # rubocop:disable Style/ParallelAssignment
    [square_from, square_to].each do |square|
      square[0] = square[0].ord - 96
      square[1] = square[1].to_i
    end
    [square_from, square_to]
  end

  def make_move(square_from, square_to)
    piece = @board_h[square_from]
    dying_piece = @board_h[square_to]
    kill = dying_piece && dying_piece.color != turn_of ? true : false
    [piece, square_from, kill, square_to, check]
  end

  private

  def create_new_board
    ## Array of 64 squares: [1,1] to [8,8]
    new_board = (1..8).to_a.product((1..8).to_a)
    # creating empty Board hash,
    new_board = new_board.to_h { |square| [square, nil] }

    # placing pawns
    (1..8).each do |col|
      new_board[[col, 2]] = Piece.new('pawn', :white)
      new_board[[col, 7]] = Piece.new('pawn', :black)
    end

    # placing remaining pieces
    pieces_seq = %w[rook knight bishop queen king bishop knight rook]
    pieces_seq.each_with_index do |piece, i|
      col = i + 1
      new_board[[col, 1]] = Piece.new(piece, :white)
      new_board[[col, 8]] = Piece.new(piece, :black)
    end

    new_board # returning board
  end

  def to_s
    board_h
  end
end

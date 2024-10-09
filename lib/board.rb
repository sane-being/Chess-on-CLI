require_relative 'piece'

module ValidMoves
  def moved_as_king?(square_from, square_to)
    [square_from, square_to] in [[col_f, row_f], [col_t, row_t]]
    ((col_f - col_t).abs <= 1) && ((row_f - row_t).abs <= 1)
  end

  def moved_as_queen?(square_from, square_to)
    moved_as_rook?(square_from, square_to) || moved_as_bishop?(square_from, square_to)
  end

  def moved_as_rook?(square_from, square_to)
    if square_from[0] == square_to[0] # moving vertically
      [square_from, square_to] in [[col, row_f], [*, row_t]]
      # range = row_f < row_t ? (row_f..row_t) : (row_t..row_f)
      range = (row_f..row_t) || (row_t..row_f)
      squares_btw = range.map { |row| [col, row] }
    elsif square_from[1] == square_to[1] # moving horizontally
      [square_from, square_to] in [[col_f, row], [col_t, *]]
      # range = col_f < col_t ? (col_f..col_t) : (col_t..col_f)
      range = (col_f..col_t) || (col_t..col_f)
      squares_btw = range.map { |col| [col, row] }
    else # not moving in a line
      return false
    end
    squares_btw -= (square_from + square_to)
    squares_btw.all? { |square| @board_h[square].nil? }
  end

  def moved_as_bishop?(square_from, square_to)
    [square_from, square_to] in [[col_f, row_f], [col_t, row_t]]
    return false if (row_t - row_f).abs != (col_t - col_f).abs # not moving cross

    rows_a = (row_f..row_t).to_a || (row_t..row_f).to_a.reverse
    cols_a = (col_f..col_t).to_a || (col_t..col_f).to_a.reverse
    squares_btw = cols_a.zip(rows_a)

    squares_btw -= (square_from + square_to)
    squares_btw.all? { |square| @board_h[square].nil? }
  end

  def moved_as_pawn?(square_from, square_to, kill, color)
    [square_from, square_to] in [[col_f, row_f], [col_t, row_t]]
    return ((col_f - col_t).abs == 1) && ((row_f - row_t).abs == 1) if kill
    return false if col_f != col_t
    return false if color == :black && (row_f < row_t)
    return false if color == :white && (row_f > row_t)

    case (row_t - row_f).abs
    when 2 then [2, 7].any?(row_f)
    when 1 then true
    else        false
    end
  end
end

class Board
  include ValidMoves
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
    @moves_a = make_move(square_from, square_to)
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

  def find_next_dest(piece)
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

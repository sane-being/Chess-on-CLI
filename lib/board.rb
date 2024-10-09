require_relative 'piece'

class Board
  include ValidMoves
  attr_accessor :board_h, :turn_of

  def initialize
    # board hash of 64 squares, square => occupying piece ('' if empty)
    @board_h = create_new_board
    @turn_of = :white
    @moves_a = []
  end

  def turn
    loop do
      move = gets
      next unless is_move_valid?(move)

      @turn_of = @turn_of == :white ? :black : :white # toggle turn
    end
  end

  def is_move_valid?(move)
    decode_move(move) in [piece, square_from, square_to]

    return false unless (square_from + square_to).flatten.all?(1..8) # Valid squares
    return false if square_from == square_to # Moving to same square
    return false if piece.color != turn_of # Player not moving his own piece

    kill = killing?(square_to)
    return false if kill.nil? # square_to is occupied by players own piece

    move_a = [piece, square_from, kill, square_to, check]

    case piece.abbr
    when :K then moved_as_king?(move_a)
    when :Q then moved_as_rook?(move_a) || moved_as_bishop?(move_a)
    when :R then moved_as_rook?(move_a)
    when :N then moved_as_knight?(move_a)
    when :B then moved_as_bishop?(move_a)
    when :"" then moved_as_pawn?(move_a)
    end
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
    pieces_seq.each_with_index do |piece, col|
      col += 1 # index starts from 0, but col starts from 1
      new_board[[col, 1]] = Piece.new(piece, :white)
      new_board[[col, 8]] = Piece.new(piece, :black)
    end

    new_board # returning board
  end

  def decode_move(move)
    move = move.split
    square_from, square_to = move[0..1], move[2..3] # rubocop:disable Style/ParallelAssignment
    [square_from, square_to].each do |square|
      square[0] = square[0].ord - 96
      square[1] = square[1].to_i
    end
    # [piece, square_from, square_to]
    [@board_h[square_from], square_from, square_to]
  end

  def killing?(square_to)
    if @board_h[square_to].nil? # square_to is empty
      false
    elsif @board_h[square_to].color == turn_of # Own piece present on square_to
      nil
    else # Opponent's piece on square_to
      true
    end
  end

  def moved_as_king?(move_a)
    move_a in [_, [col_f, row_f], _, [col_t, row_t], _]
    ((col_f - col_t).abs <= 1) && ((row_f - row_t).abs <= 1)
  end

  def moved_as_rook?(move_a)
    move_a in [_, [col_f, row_f], _, [col_t, row_t], _]

    if col_f == col_t # moving vertically
      col = col_f
      rows_a = (row_f..row_t) || (row_t..row_f)
      squares_btw = rows_a.map { |row| [col, row] }
    elsif row_f == row_t # moving horizontally
      row = row_f
      cols_a = (col_f..col_t) || (col_t..col_f)
      squares_btw = cols_a.map { |col| [col, row] }
    else # not moving in a straight line
      return false
    end

    squares_btw -= ([col_f, row_f] + [col_t, row_t])
    squares_btw.all? { |square| @board_h[square].nil? }
  end

  def moved_as_bishop?(move_a)
    move_a in [_, [col_f, row_f], _, [col_t, row_t], _]
    return false if (row_t - row_f).abs != (col_t - col_f).abs # not moving cross

    rows_a = (row_f..row_t).to_a || (row_t..row_f).to_a.reverse
    cols_a = (col_f..col_t).to_a || (col_t..col_f).to_a.reverse
    squares_btw = cols_a.zip(rows_a)

    squares_btw -= ([col_f, row_f] + [col_t, row_t])
    squares_btw.all? { |square| @board_h[square].nil? }
  end

  def moved_as_knight?(move_a)
    move_a in [_, [col_f, row_f], _, [col_t, row_t], _]

    condition = [(col_t - col_f).abs, (row_t - row_f).abs]
    condition.one?(1) && condition.one?(2)
  end

  def moved_as_pawn?(move_a)
    move_a in [piece, [col_f, row_f], kill, [col_t, row_t], _]
    color = piece.color

    return false if color == :black && (row_f < row_t)  # black pawn moving upwards
    return false if color == :white && (row_f > row_t)  # white pawn moving downwards
    # if killing, checking whether pawn is moving one square cross or not
    return ((col_f - col_t).abs == 1) && ((row_f - row_t).abs == 1) if kill
    return false if col_f != col_t # not moving in a column

    case (row_t - row_f).abs
    when 2 # pawn making move of 2 squares
      return false if [2, 7].none?(row_f) # pawn is not at its initial row

      square_btw = color == :black ? [col_f, row_f - 1] : [col_f, row_f + 1]
      return @board_h[square_btw].nil? # square between is empty # rubocop:disable Style/RedundantReturn
    when 1 then true # pawn moving one step
    else false
    end
  end

  def to_s
    board_h
  end
end

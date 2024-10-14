require_relative 'piece'

class Board
  attr_accessor :board_h, :turn_of

  def initialize
    # board hash of 32 pieces, piece => array of squares attacking
    @board_h = create_new_board
    @turn_of = :white
    @pieces_h = a
    # @moves_a = []
  end

  def play
    loop do
      self.pretty_print # rubocop:disable Style/RedundantSelf
      print "move of #{turn_of}:"
      move_a = decode_move(gets)
      if is_move_valid?(move_a)
        move_piece(move_a)
        toggle_turn
      else
        puts 'Invalid input!'
      end
    end
  end

  def pretty_print
    puts ' '
    board_h.each do |square, piece|
      print piece ? piece.symbol : '_'         # square
      print ' '                                # space between squares
      puts "   #{square[1]}" if square[0] == 8 # row number labels
    end
    puts "\na b c d e f g h\n "                # column labels
  end

  def move_piece(move_a)
    move_a in [piece, square_from, _, square_to, _]
    board_h.store(square_to, piece)
    board_h.store(square_from, nil)
  end

  def toggle_turn
    @turn_of = case @turn_of
               when :white then :black
               when :black then :white
               end
  end

  def create_new_board
    ## Array of 64 squares: [1,1] to [8,8]
    new_board = []
    (1..8).to_a.reverse.each { |row| new_board += (1..8).to_a.product([row]) }
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
    move = move.split('')
    square_from, square_to = move[0..1], move[2..3] # rubocop:disable Style/ParallelAssignment
    [square_from, square_to].each do |square|
      square[0] = square[0].ord - 96
      square[1] = square[1].to_i
    end
    # [piece, square_from, square_to]
    [@board_h[square_from], square_from, square_to]
  end

  def is_move_valid?(move_a)
    move_a in [piece, square_from, square_to]

    return false unless (square_from + square_to).flatten.all?(1..8) # Valid squares
    return false if square_from == square_to # Moving to same square
    return false if piece.color != turn_of # Player not moving his own piece

    kill = killing?(square_to)
    return false if kill.nil? # square_to is occupied by players own piece

    move_a.insert(2, kill)
    move_a.push('check')
    # move_a = [Piece, square_from, kill, square_to, 'check']

    case piece.abbr
    when :K then moved_as_king?(move_a)
    when :Q then moved_as_rook?(move_a) || moved_as_bishop?(move_a)
    when :R then moved_as_rook?(move_a)
    when :N then moved_as_knight?(move_a)
    when :B then moved_as_bishop?(move_a)
    when :"" then moved_as_pawn?(move_a)
    end
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
      rows_a = (row_f..row_t).to_a + (row_t..row_f).to_a
      squares_btw = rows_a.map { |row| [col, row] }
    elsif row_f == row_t # moving horizontally
      row = row_f
      cols_a = (col_f..col_t).to_a + (col_t..col_f).to_a
      squares_btw = cols_a.map { |col| [col, row] }
    else # not moving in a straight line
      return false
    end

    squares_btw -= [[col_f, row_f], [col_t, row_t]]
    squares_btw.all? { |square| @board_h[square].nil? }
  end

  def moved_as_bishop?(move_a)
    move_a in [_, [col_f, row_f], _, [col_t, row_t], _]
    return false if (row_t - row_f).abs != (col_t - col_f).abs # not moving cross

    rows_a = (row_f..row_t).to_a + (row_t..row_f).to_a.reverse
    cols_a = (col_f..col_t).to_a + (col_t..col_f).to_a.reverse
    squares_btw = cols_a.zip(rows_a)

    squares_btw -= [[col_f, row_f], [col_t, row_t]]
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

  ###########################################################################
  #
  def attacks(piece)
    pieces_h[piece] = case piece.abbr
                      when :K then moved_as_king?(move_a)
                      when :Q
                        array = rook_attacks(piece.square, piece.color)
                        array += bishop_attacks(piece.square, piece.color)
                        array
                      when :R then rook_attacks(piece.square, piece.color)
                      when :N then knight_attacks(piece.square, piece.color)
                      when :B then bishop_attacks(piece.square, piece.color)
                      when :"" then moved_as_pawn?(move_a)
                      end
  end

  def push?(square_btw, array, color)
    if board_h[square_btw].nil? || board_h[square_btw].color != color
      array.push(square_btw)
      true
    else
      false
    end
  end

  def rook_attacks(square, color, array = [])
    square in [col, row]

    ((col + 1)..8).each { |col_b| break unless push?([col_b, row], array, color) }
    ((col - 1)..1).each { |col_b| break unless push?([col_b, row], array, color) }
    ((row + 1)..8).each { |row_b| break unless push?([col, row_b], array, color) }
    ((row - 1)..1).each { |row_b| break unless push?([col, row_b], array, color) }

    array
  end

  def bishop_attacks(square, color, array = [])
    [1, -1].each do |c|
      [-1, 1].each do |r|
        square in [col_b, row_b]
        loop do
          col_b += c
          row_b += r
          break if (1..8).none?(col_b) || (1..8).none?(row_b)
          break unless push?([col_b, row_b], array, color)
        end
      end
    end
    array
  end

  def knight_attacks(piece)
    piece.square in [col, row]
    piece.color in color

    array = [col + 2, col - 2].product([row + 1, row - 1]) +
            [col + 1, col - 1].product([row + 2, row - 2])

    array.select! do |square|
      c1 = square.all? { |num| (1..8).include? num }
      c2 = board_h[square].nil?
      c3 = board_h[square].color != color
      c1 && (c2 || c3)
    end
    array
  end
end

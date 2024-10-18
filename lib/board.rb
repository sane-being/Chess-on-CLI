require_relative 'piece'
require_relative 'attack'
require_relative 'create_board'

class Board
  include CreateNewBoard
  include AttackSquare
  attr_accessor :board_h, :pieces_h, :turn_of, :moves_log

  def initialize
    # Hash of 64 squares on board as keys, square => piece on square
    @board_h = create_board.to_h { |square| [square, nil] }

    # Hash of all the pieces (32), piece => squares attackable by it on next move
    @pieces_h = create_pieces.to_h do |piece|
      @board_h[piece.square] = piece # placing pieces on the board (@board_h)
      [piece, attacks(piece)]
    end

    @turn_of = :white
    @moves_log = []
  end

  def play
    loop do
      valid_move = false
      pretty_print
      begin
        print "Turn of #{turn_of}:"
        move_a = decode_move(gets)
        valid_move = is_move_valid?(move_a)
        killing?(move_a)
        move_piece(move_a)
        getting_or_giving_check?(move_a)
      rescue StandardError => e
        puts "Invalid input! #{e.message}\nEnter again!"
        undo(move_a) if valid_move
        retry
      else
        cm = checkmate?(move_a)
        log_this_move(move_a)
        break if cm

        toggle_turn
      end
    end
    pretty_print
    puts "CHECKMATE!\n#{turn_of} wins!"
  end

  def checkmate?(move_a)
    move_a in [_, _, _, _, check]

    return false if check.nil?

    king = turn_of == :white? ? black_king : white_king
    possible_moves = pieces_h[king].clone

    pieces_h.each do |piece_upd, array|
      next if array.nil? || piece_upd.color != turn_of

      possible_moves -= array
      next unless possible_moves.empty?

      move_a[4] = :'#'
      return true
    end
    false
  end

  def log_this_move(move_a)
    moves_log.push(move_a)
  end

  def undo(move_a)
    move_a in [piece, square_from, dying_piece, square_to, _]

    piece.square = square_from
    dying_piece.square = square_to unless dying_piece.nil?

    board_h[square_from] = piece
    board_h[square_to] = dying_piece

    pieces_h.each_key do |piece_upd|
      pieces_h.store(piece_upd, attacks(piece_upd))
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

  def decode_move(move)
    square_from = move[0..1].split('')
    square_to = move[2..3].split('')

    [square_from, square_to].each do |square|
      square[0] = square[0].ord - 96
      square[1] = square[1].to_i
    end
    # [piece, square_from, kill, square_to, check]
    [@board_h[square_from], square_from, nil, square_to, nil]
  end

  def is_move_valid?(move_a)
    move_a in [piece, square_from, _, square_to, _]
    if !(square_valid?(square_from) && square_valid?(square_to))
      raise "Enter the input in format: <square_from><square_to>
  example: input 'e2e4' to move the pawn"
    elsif square_from == square_to
      raise 'Plaese move piece to a different square'
    elsif piece.nil?
      raise 'No piece present on selected square'
    elsif piece.color != turn_of
      raise "Plaese move your own piece (#{piece.color})"
    elsif piece.abbr == :""
      return true if moving_as_pawn?(square_from, square_to, piece.color)
      return true if pieces_h[piece].include?(square_to) &&
                     !square_empty?(square_to)

      raise 'Play as per rules!'
    elsif pieces_h[piece].include? square_to
      true
    else
      raise 'Play as per rules!'
    end
  end

  def killing?(move_a)
    move_a in [_, _, _, square_to, _]

    dying_piece = board_h[square_to]
    move_a[2] = dying_piece

    case dying_piece
    when nil then false
    else
      dying_piece.square = nil
      pieces_h[dying_piece] = nil
      true
    end
  end

  def getting_or_giving_check?(move_a)
    kings_under_check = []

    pieces_h.each do |piece_upd, array|
      next if array.nil? # piece is dead

      kings_under_check.push(:white) if piece_upd.color == :black &&
                                        array.include?(white_king.square)
      kings_under_check.push(:black) if piece_upd.color == :white &&
                                        array.include?(black_king.square)
    end

    if kings_under_check.empty?
      false
    elsif kings_under_check.include? turn_of
      raise 'Your king is getting exposed to a check!'
    else
      move_a[4] = :+
      true
    end
  end

  def move_piece(move_a)
    move_a in [piece, square_from, _, square_to, _]

    piece.square = square_to

    board_h.store(square_to, piece)
    board_h.store(square_from, nil)

    pieces_h.each_key do |piece_upd|
      pieces_h.store(piece_upd, attacks(piece_upd))
    end
  end

  def toggle_turn
    @turn_of = case @turn_of
               when :white then :black
               when :black then :white
               end
  end
end

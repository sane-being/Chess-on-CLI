require_relative 'piece'
require_relative 'attack'
require_relative 'create_board'

class Board
  include CreateBoard
  include AttackSquare
  attr_accessor :board_h, :turn_of, :pieces_h

  def initialize
    # board hash of 32 pieces, piece => array of squares attacking
    @board_h = create_new_board
    @pieces_h = create_pieces
    @turn_of = :white
    # @moves_a = []
  end

  def play
    loop do
      self.pretty_print # rubocop:disable Style/RedundantSelf
      print "move of #{turn_of}:"
      move_a = decode_move(gets)
      if is_move_valid?(move_a)
        killing?(move_a)
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

    return false unless square_valid?(square_from) && square_valid?(square_to)
    return false if square_from == square_to # Moving to same square
    return false if piece.nil? # piece not present on square_from
    return false if piece.color != turn_of # Player not moving his own piece

    return true if (piece.abbr == :"") &&
                   moving_as_pawn?(square_from, square_to, piece.color)

    pieces_h[piece].include? square_to
  end

  def killing?(move_a)
    move_a in [_, _, _, square_to, _]

    kill = board_h[square_to].nil? ? nil : :x
    move_a[2] = kill

    case kill
    when nil then false
    when :x
      dying_piece = board_h[square_to]
      pieces_h.delete(dying_piece)
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

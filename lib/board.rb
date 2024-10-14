require_relative 'piece'
require_relative 'attack'
require_relative 'create_board'

class Board
  include CreateBoard
  include AttackSquare
  attr_accessor :board_h, :turn_of, :pieces_h,
                :white_king, :black_king

  def initialize
    # board hash of 32 pieces, piece => array of squares attacking
    @board_h = create_new_board
    @pieces_h = create_pieces
    @turn_of = :white
    @white_king = Piece.new('king', :white, [5, 1])
    @black_king = Piece.new('king', :black, [5, 8])
    # @moves_a = []
  end

  def play
    loop do
      pp pieces_h
      self.pretty_print # rubocop:disable Style/RedundantSelf
      copy_pieces_h = pieces_h.clone
      # copy_pieces_h = {}
      # pieces_h.each { |p, a| copy_pieces_h[p.clone] = a }
      begin
        print "move of #{turn_of}:"
        move_a = decode_move(gets)
        is_move_valid?(move_a)
        killing?(move_a)
        move_piece(move_a)
        getting_or_giving_check?(move_a)
        toggle_turn
        pp move_a
      rescue StandardError => e
        puts "Invalid input! #{e.message}\nEnter again!"
        @pieces_h = copy_pieces_h
        retry
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

    if square_from == square_to
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

    kill = board_h[square_to].nil? ? nil : :x
    move_a[2] = kill

    case kill
    when nil then false
    when :x
      dying_piece = board_h[square_to]
      pieces_h.delete(dying_piece)
    end
  end

  def getting_or_giving_check?(move_a)
    kings_under_check = []

    pieces_h.each do |piece_upd, array|
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

require_relative 'player'
require_relative 'attack_map'
class Board
  include AttackMap

  ERROR_MESSAGES = {
    1 => "Enter the input in format: <square_from><square_to>
example: input 'e2e4' to move the pawn",
    2 => 'Plaese move piece to a different square',
    3 => 'No piece present on selected square',
    4 => 'Plaese move your own piece',
    5 => 'Play as per rules!',
    6 => 'Your king is getting exposed to a check!'
  }.freeze

  attr_accessor :board_h, :player_white, :player_black,
                :act_player, :opp_player, :moves_log

  def initialize
    # Hash of 64 squares on board as keys, square => piece on square
    @board_h = create_board

    # players
    @player_white = Player.new(:white)
    @player_black = Player.new(:black)

    @moves_log = []

    place_pieces_on_board
  end

  def play
    is_checkmate = false
    players = [@player_white, @player_black]
    until is_checkmate
      @act_player, @opp_player = players
      is_piece_moved = false
      pretty_print
      begin
        print "Turn of #{act_player}:"
        move_a = decode_move(gets)
        check_validity_1(move_a)
        kill_piece_if_any(move_a)
        move_piece(move_a)
        is_piece_moved = true
        check_validity_2
      rescue StandardError => e
        puts "Invalid input! #{e.message}\nEnter again!"
        undo(move_a) if is_piece_moved
        retry
      end
      give_check_if_applies(move_a)
      is_checkmate = checkmate?(move_a)
      moves_log.push(move_a)
      players.reverse!
    end
    pretty_print
    puts "CHECKMATE!\n#{act_player} wins!"
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
    [board_h[square_from], square_from, nil, square_to, nil]
  end

  def check_validity_1(move_a)
    move_a in [piece, square_from, _, square_to, _]

    error_no =
      case
      when !(square_valid?(square_from) && square_valid?(square_to)) then 1
      when square_from == square_to        then 2
      when piece.nil?                      then 3
      when piece.color != act_player.color then 4
      when piece.name == 'pawn'
        return if moving_as_pawn?(square_from, square_to, piece.color) || # pawn is moving
                  (!square_empty?(square_to) && # pawn is killing
                  act_player.attack_map[piece].include?(square_to))

        5
      when act_player.attack_map[piece].include?(square_to) then return
      else 5
      end

    raise ERROR_MESSAGES[error_no]
  end

  def kill_piece_if_any(move_a)
    move_a in [_, _, _, square_to, _]

    return move_a if square_empty?(square_to)

    dying_piece = board_h[square_to]
    move_a[2] = dying_piece   # add dying piece to move_a
    dying_piece.square = nil  # removing square details of dying_piece object
    opp_player.attack_map[dying_piece] = nil # removing attack_map of dying_piece
  end

  # checking if active player is getting check
  def check_validity_2
    opp_player.attack_map.each_value do |array|
      next if array.nil? # piece is dead
      raise ERROR_MESSAGES[6] if array.include? act_player.king.square
    end
  end

  # checking  if check has been given to the opponent
  def give_check_if_applies(move_a)
    act_player.attack_map.each_value do |array|
      next if array.nil? # piece is dead

      move_a[4] = :+ if array.include? opp_player.king.square
    end
  end

  # move piece & update related objects
  def move_piece(move_a)
    move_a in [piece, square_from, _, square_to, _]

    # update piece object
    piece.square = square_to

    # update @board_h
    board_h.store(square_to, piece)
    board_h.store(square_from, nil)

    update_attack_maps
  end

  # checking if opponent player is checkmate
  def checkmate?(move_a)
    move_a in [_, _, _, _, check]

    # kill check giver
    # block check giver with other piece
    # move king to another location

    return false if check.nil?

    # getting possible moves for the king of opponent
    king = opp_player.king
    possible_moves = opp_player.attack_map[king].clone

    # getting an array of all the squares attacked by any of the pieces of active player
    attack_map_act = act_player.attack_map.values.flatten(1)

    # removing attacked squares from possible moves (where opp will get check)
    possible_moves -= attack_map_act

    pp possible_moves

    return false unless possible_moves.empty?

    move_a[4] = :'#'
    true
  end

  # undo executed move
  def undo(move_a)
    move_a in [piece, square_from, dying_piece, square_to, _]

    # update piece objects
    piece.square = square_from
    dying_piece.square = square_to unless dying_piece.nil?

    # update @board_h
    board_h[square_from] = piece
    board_h[square_to] = dying_piece

    update_attack_maps
  end

  def update_attack_maps
    [player_white, player_black].each do |player|
      map = player.attack_map
      map.each_key { |piece| map[piece] = attacks(piece) }
    end
  end

  # Create new board, an array of 64 squares: [1,1] to [8,8]
  def create_board
    new_board_a = []
    (1..8).to_a.reverse.each { |row| new_board_a += (1..8).to_a.product([row]) }
    new_board_a.to_h { |square| [square, nil] }
  end

  # placing pieces on the board (@board_h)
  def place_pieces_on_board
    [player_white, player_black].each do |player|
      player.attack_map.each_key do |piece_upd|
        board_h[piece_upd.square] = piece_upd
      end
    end

    update_attack_maps
  end
end

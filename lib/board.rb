require 'yaml'
require_relative 'player'
require_relative 'attack_map'
require_relative 'piece'
class Board
  include AttackMap

  WELCOME = "----- CHESS on CLI -----

1. New Game
2. Load Game

Press the number to select: ".freeze

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

    @is_checkmate = false
    @moves_log = []

    place_pieces_on_board
  end

  def play
    puts WELCOME
    load_game if gets.chomp == '2'
    until @is_checkmate
      pretty_print
      play_turn
    end
    puts "CHECKMATE!\n#{act_player} wins!"
  end

  def find_act_player
    # returns [@act_player, @opp_player]
    case moves_log.length % 2
    when 0 then [@player_white, @player_black]
    when 1 then [@player_black, @player_white]
    end
  end

  def move_from_user
    print "Turn of #{act_player}:"
    move = gets.chomp
    if move == 's'
      save_game
      raise 'Game saved successfully'
    end
    move
  end

  def play_turn(move_a = nil)
    @act_player, @opp_player = find_act_player
    is_piece_moved = false
    begin
      move_a = decode_move(move_from_user) if move_a.nil?
      check_validity_1(move_a)
      kill_piece_if_any(move_a)
      move_piece(move_a)
      is_piece_moved = true
      check_validity_2
    rescue StandardError => e
      puts e.message
      undo(move_a) if is_piece_moved
      move_a = nil
      retry
    end
    give_check_if_applies(move_a)
    @is_checkmate = checkmate?(move_a)
    move_a[4] = :'#' if @is_checkmate
    moves_log.push(move_a)
  end

  def pretty_print
    puts "Enter 's' to save game"
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
      when (piece.name == 'pawn') && # pawn is moving
           pawn_moves(square_from, piece.color).include?(square_to)
        then return
      when act_player.attack_map[piece].include?(square_to) then return
      else 5
      end

    raise "Invalid input! #{ERROR_MESSAGES[error_no]}\nEnter again!"
  end

  def kill_piece_if_any(move_a)
    move_a in [_, _, _, square_to, _]

    return move_a if square_empty?(square_to)

    dying_piece = board_h[square_to]
    move_a[2] = dying_piece   # add dying piece to move_a
    dying_piece.square = nil  # removing square details of dying_piece object
    opp_player.attack_map[dying_piece] = nil # removing attack_map of dying_piece
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

  # checking if active player is getting check
  def check_validity_2
    opp_player.attack_map.each_value do |array|
      next if array.nil? # piece is dead
      raise ERROR_MESSAGES[6] if array.include? act_player.king.square
    end
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

  # checking  if check has been given to the opponent
  def give_check_if_applies(move_a)
    act_player.attack_map.each_value do |array|
      next if array.nil? # piece is dead

      move_a[4] = :+ if array.include? opp_player.king.square
    end
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

  # checking if opponent player is checkmate
  def checkmate?(move_a)
    move_a in [_, _, _, square_to, check]

    return false if check.nil?

    ### Attempt 1 ###
    # Move opponent's king to another location

    # getting an array of all the squares attacked by any of the pieces of active player
    act_attack_map = act_player.attack_map.values.flatten(1)
    # getting possible moves for the king of opponent to flee
    opp_king_flee_map = opp_player.attack_map[opp_player.king].clone
    opp_king_flee_map -= act_attack_map

    return false unless (opp_king_flee_map - [square_to]).empty?

    # find check giver pieces of active player
    checker_pieces_h = act_player.attack_map.select do |_, attack_a|
      attack_a.include?(opp_player.king.square)
    end
    # If there are more than one check giving pieces, and since king can't flee, it'd be a checkmate
    # Because one move can kill/block only one check giver
    return true if checker_pieces_h.length > 1

    ### Attempt 2 ###
    # Kill check giver using pieces other than king

    checker_piece = checker_pieces_h.keys[0]
    # Trying to kill check giver by any piece but king
    # getting an array of all the squares attacked by any of the pieces of opponent player
    opp_attack_map = opp_player.attack_map.reject { |piece_upd, _| piece_upd == opp_player.king }
    opp_attack_map = opp_attack_map.values.flatten(1)

    return false if opp_attack_map.include? checker_piece.square

    ### Attempt 3 ###
    # Block check giver

    if %w[rook bishop queen].include? checker_piece.name
      # Finding line of check
      [opp_player.king.square, checker_piece.square] in [[col_k, row_k], [col_a, row_a]]
      c = col_k <=> col_a
      r = row_k <=> row_a
      line_of_check = linear_attack(checker_piece.square, checker_piece.color) { |col, row| [col + c, row + r] }
      line_of_check -= [opp_player.king.square]

      # checking if any of the pieces can block line of check
      can_block_on = line_of_check & opp_attack_map
      return false unless can_block_on.empty?
      # bug: pawns moving are not included in this yet
    end

    ### Attempt 4 (final) ###
    # Kill check giver by king

    return true unless opp_king_flee_map.include? square_to

    # Implies that the square_to == checker_piece.square, & is adjacent to the opp king
    esc_move = [opp_player.king, opp_player.king.square, nil, square_to, nil]
    @act_player, @opp_player = @opp_player, @act_player
    begin
      kill_piece_if_any(esc_move)
      move_piece(esc_move)
      check_validity_2
      is_king_exposed = false
    rescue StandardError # king is gone
      is_king_exposed = true
    end
    undo(esc_move)
    @act_player, @opp_player = @opp_player, @act_player
    is_king_exposed
  end

  def save_game
    Dir.mkdir('save') unless Dir.exist?('save')
    puts 'Rename your save file:'
    filename = gets.chomp.downcase
    moves_log_to_yaml = YAML.dump({ moves_log: moves_log })
    File.open("save/#{filename}.yml", 'w') { |file| file.write(moves_log_to_yaml) }
  end

  def load_game
    filename = take_filename_from_user
    data = YAML.load_file filename
    loaded_moves_log = data[:moves_log]
    loaded_moves_log.each { |move_a| play_turn(move_a) }
  end

  def take_filename_from_user
    files_list = Dir.glob('save/*.yml') # Lists all save files, stores in array

    # print files_list
    puts "\nSave files:\n"
    files_list.each_with_index do |filename, ind|
      filename = filename.sub('save/', '').sub('.yml', '')
      puts "#{ind}. #{filename}"
    end

    # get user input & load respective game from yml file
    begin
      puts "\nPress the number to select: "
      ind = gets.chomp.to_i
      filename = files_list[ind]
    rescue StandardError
      puts 'Incorrect entry. Please select a valid index number of save file :'
      retry
    end
    filename
  end
end

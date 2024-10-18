module AttackMap
  # returns an array of squares, that the piece can attack on next move
  def attacks(piece)
    return nil if piece.square.nil? # piece is dead

    case piece.abbr
    when :K then king_attacks(piece.square, piece.color)
    when :Q then rook_attacks(piece.square, piece.color) +
      bishop_attacks(piece.square, piece.color)
    when :R then rook_attacks(piece.square, piece.color)
    when :N then knight_attacks(piece.square, piece.color)
    when :B then bishop_attacks(piece.square, piece.color)
    when :"" then pawn_attacks(piece.square, piece.color)
    end
  end

  ########################################
  # Piecewise methods to generate that array

  def pawn_attacks(square, color)
    square in [col, row]
    r = color == :white ? 1 : -1

    array = [[col + 1, row + r], [col - 1, row + r]]
    array.select! { |square_to| attack_square?(square_to, color) }
    array
  end

  def moving_as_pawn?(square_from, square_to, color)
    [square_from, square_to] in [[col_f, row_f], [col_t, row_t]]

    return false unless square_valid?([col_t, row_t]) &&
                        col_f == col_t                &&
                        square_empty?([col_t, row_t])

    return false unless (color == :black && (row_f > row_t)) ||
                        (color == :white && (row_f < row_t))

    case (row_t - row_f).abs
    when 2 # pawn making move of 2 squares
      return false if [2, 7].none?(row_f) # pawn is not at its initial row

      square_btw = color == :black ? [col_f, row_f - 1] : [col_f, row_f + 1]
      @board_h[square_btw].nil? # square between is empty
    when 1 then true # pawn moving one step
    else        false
    end
  end

  def king_attacks(square, color)
    square in [col, row]
    col_a = ((col - 1)..(col + 1)).to_a
    row_a = ((row - 1)..(row + 1)).to_a

    array = col_a.product row_a - square
    array.select! { |square_to| attack_square?(square_to, color) }
    array
  end

  def knight_attacks(square, color)
    square in [col, row]

    array = [col + 2, col - 2].product([row + 1, row - 1]) +
            [col + 1, col - 1].product([row + 2, row - 2])
    array.select! { |square_to| attack_square?(square_to, color) }
    array
  end

  def rook_attacks(square, color)
    right = linear_attack(square, color) { |col, row| [col + 1, row] }
    left = linear_attack(square, color) { |col, row| [col - 1, row] }
    up = linear_attack(square, color) { |col, row| [col, row + 1] }
    down = linear_attack(square, color) { |col, row| [col, row - 1] }

    right + left + up + down
  end

  def bishop_attacks(square, color)
    up_right = linear_attack(square, color) { |col, row| [col + 1, row + 1] }
    up_left = linear_attack(square, color) { |col, row| [col - 1, row + 1] }
    down_right = linear_attack(square, color) { |col, row| [col + 1, row - 1] }
    down_left = linear_attack(square, color) { |col, row| [col - 1, row - 1] }

    up_right + up_left + down_right + down_left
  end

  def linear_attack(square, color, &block)
    line_a = []
    square_nxt = square.clone

    loop do
      square_nxt = block.call(*square_nxt) # get next square
      return line_a unless square_valid?(square_nxt)

      line_a.push(square_nxt) if square_empty?(square_nxt) ||
                                 can_kill?(square_nxt, color)
      return line_a if !square_empty?(square_nxt) # rubocop:disable Style/NegatedIf
    end
  end

  ##############################################
  # Methods to check conditions on particular square

  def square_valid?(square_to)
    square_to.all? { |num| (1..8).include?(num) }
  end

  def square_empty?(square_to)
    board_h[square_to].nil?
  end

  def can_kill?(square_to, color)
    board_h[square_to].color != color
  end

  def attack_square?(square_to, color)
    c1 = square_valid?(square_to)
    c2 = square_empty?(square_to) || can_kill?(square_to, color)
    c1 && c2
  end
end

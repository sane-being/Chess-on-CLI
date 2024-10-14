module AttackSquare
  # returns an array of squares, that the piece can attack on next move
  def attacks(piece)
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

  def king_attacks(square, color)
    square in [col, row]
    col_a = ((col - 1)..(col + 1)).to_a
    row_a = ((row - 1)..(row + 1)).to_a

    array = col_a.product row_a - square
    array.select! { |square_to| attack_square?(square_to, color) }
    array
  end

  def rook_attacks(square, color, array = [])
    (0..1).each do |roc|
      [-1, 1].each do |i|
        square_to = square
        while square_valid?(square_to)
          if square_to == square
            square_to[roc] += i
          elsif square_empty?(square_to)
            array.push(square_to)
            square_to[roc] += i
          else
            array.push(square_to) if can_kill?(square_to, color)
            break
          end
        end
      end
    end
    array
  end

  def bishop_attacks(square, color, array = [])
    [1, -1].each do |c|
      [-1, 1].each do |r|
        square in square_to
        while square_valid?(square_to)
          if square_to == square
            square_to[0] += c
            square_to[1] += r
          elsif square_empty?(square_to)
            array.push(square_to)
            square_to[0] += c
            square_to[1] += r
          else
            array.push(square_to) if can_kill?(square_to, color)
            break
          end
        end
      end
    end
    array
  end

  def knight_attacks(square, color)
    square in [col, row]

    array = [col + 2, col - 2].product([row + 1, row - 1]) +
            [col + 1, col - 1].product([row + 2, row - 2])
    array.select! { |square_to| attack_square?(square_to, color) }
    array
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

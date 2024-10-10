require_relative '../lib/board'
require_relative '../lib/piece'

describe Board do
  subject(:chess_game1) { Board.new }
  let(:pawn) { instance_double(Piece, color: :white, abbr: :"") }

  describe '#decode_move' do
    context 'when passed with valid move "e2e4"' do
      it 'returns [<pawn_obj>, [5,2], [5,4]]' do
        move = 'e2e4'
        result = [[5, 2], [5, 4]]
        expect(chess_game1.decode_move(move)[1..]).to eql(result)
        expect(chess_game1.decode_move(move)[0].abbr).to eql(:"")
        expect(chess_game1.decode_move(move)[0].color).to eql(:white)
      end
    end
  end

  describe '#killing?' do
    context 'when passed with empty square_to [1,3]' do
      it 'returns false' do
        square_to = [1, 3]
        expect(chess_game1.killing?(square_to)).to be false
      end
    end
  end

  describe '#moved_as_pawn?' do
    context 'when passed with details of first move of white pawn' do
      # move_a = [Piece, square_from, kill, square_to, 'check']
      it 'returns true' do
        square_from = [5, 2]
        kill = false
        square_to = [5, 4]
        move_a = [pawn, square_from, kill, square_to, 'check']
        expect(chess_game1.moved_as_pawn?(move_a)).to be true
      end
    end
  end

  describe '#is_move_valid?' do
    context 'when passed with details of first move of white pawn' do
      # move_a = [Piece, square_from, square_to]
      it 'returns true' do
        square_from = [5, 2]
        square_to = [5, 4]
        move_a = [pawn, square_from, square_to]
        expect(chess_game1.is_move_valid?(move_a)).to be true
      end
    end
  end

  describe '#play' do
  end
end

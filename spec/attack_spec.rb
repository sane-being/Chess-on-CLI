require_relative '../lib/attack'
require_relative '../lib/board'

describe Board do
  describe '#moving_as_pawn?' do
    subject { Board.new }
    context 'when passed with invalid move' do
      it 'returns false' do
        square_from = [5, 5]
        square_to = [5, 4]
        color = :black
        expect(subject.moving_as_pawn?).to be false
      end
    end
  end
end

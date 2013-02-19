describe "Card" do
  let(:card_sa) { Card.new :spade, :ace } 
  
  def card(suit, rank)
    Card.new suit, rank
  end
  
  it 'have proper constructor' do
    lambda { card(:asd, :r19) }.should raise_error ArgumentError
  end

  it 'have proper string representation' do
    card(:spade, :ace).should eq "sa"
    card(:clubs, :jack).should eq "cj"
    card(:diamonds, :r7).should eq "d7"
    card(:heart, :r10).should eq "h10"
  end
  
  it 'can be equal to other card' do
    card(:heart, :r10).should eq card(:heart, :r10)
    card(:diamond, :ace).should eq card(:diamond, :ace)
    card(:spade, :king).should eq card(:spade, :king)
  end
end
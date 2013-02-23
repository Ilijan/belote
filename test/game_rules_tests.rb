describe 'GameMode' do
  let(:logic) do
    class Test
      include GameMode
    end
    Test.new
  end
  
  def card(short)
    Card.make_card_short(short)
  end

  def hand(*cards)
    Hand.new *cards;
  end

  def cards_arr(*strs)
    strs.map { |short| send(:card, short) }
  end
  
  it 'can specify game trumps' do
    logic.set_trump_suits(:spade)
    logic.trump?(card('sa')).should be_true
    logic.trump?(card('s10')).should be_true
    
    logic.trump?(card('d10')).should be_false
    logic.trump?(card('ca')).should be_false
    logic.trump?(card('h9')).should be_false
    
    
    logic.set_trump_suits :none
    logic.trump?(card('sa')).should be_false
    logic.trump?(card('s10')).should be_false
    logic.trump?(card('h9')).should be_false
    
    
    logic.set_trump_suits :spade, :heart
    logic.trump?(card('sq')).should be_true
    logic.trump?(card('hq')).should be_true
    
    logic.trump?(card('dq')).should be_false
    logic.trump?(card('c10')).should be_false
    
    logic.set_trump_suits :all
    logic.trump?(card('sq')).should be_true
    logic.trump?(card('hq')).should be_true
    logic.trump?(card('dq')).should be_true
    logic.trump?(card('c10')).should be_true
  end
  
  it 'compare card ranks from required suits by given rank order' do
    logic.compare_ranks(card('sk'), card('sq'), :spade, GameMode::TRUMP_RANKS_ORDER).should eq 1
    logic.compare_ranks(card('sk'), card('sq'), :spade, GameMode::TRUMP_RANKS_ORDER).should eq 1
  end
  
  it 'compare cards' do
    logic.set_trump_suits :none
    result = logic.compare_cards(card('sa'), card('sk'), :spade)
    result.should eq 1
  end
end
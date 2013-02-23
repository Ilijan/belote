require_relative 'short_defines'
describe 'GameMode' do
  let(:logic) do
    class Test
      include GameMode
    end
    Test.new
  end
  
  it 'can specify game trumps' do
    # func = lambda { |a| logic.trump? a }
    # tests1 = [
      # ['sa', true],
      # ['s10', true],
      # ['d10', false],
      # ['ca', false],
      # ['h9', false],
    # ]
    
    # test_function(func, tests1.map { |test_case| [card(test_case[0]), test_case[1]] })
  
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
    tests = [
      ['sk', 'sq', :spade, GameMode::TRUMP_RANKS_ORDER, 1],
      ['sj', 'sa', :spade, GameMode::TRUMP_RANKS_ORDER, 1],
      ['sj', 'sa', :spade, GameMode::NO_TRUMP_RANKS_ORDER, -1],
      ['sj', 'sa', :heart, GameMode::NO_TRUMP_RANKS_ORDER, 0],
      ['cj', 'sa', :clubs, GameMode::NO_TRUMP_RANKS_ORDER, 1],
      ['c7', 'dj', :clubs, GameMode::TRUMP_RANKS_ORDER, 1],
      ['d7', 'h9', :clubs, GameMode::TRUMP_RANKS_ORDER, 0],
      ['d7', 'h9', :clubs, GameMode::NO_TRUMP_RANKS_ORDER, 0],
    ]
    
    func = lambda { |card1, card2, suit, rank_order| logic.compare_ranks card1, card2, suit, rank_order }
    data = tests.map do |test_case|
      [card(test_case[0]), card(test_case[1])].push *test_case[2..4]
    end
    test_function func, data
    
    lambda { logic.compare_ranks(card('sa'), card('sq'), :none, GameMode::NO_TRUMP_RANKS_ORDER) }.should raise_error ArgumentError
  end
  
  describe 'compare cards' do
    def compare(tests, logic)
      func = lambda { |card1, card2, suit| logic.compare_cards card1, card2, suit }
      data = tests.map do |test_case|
        [card(test_case[0]), card(test_case[1])].push *test_case[2..3]
      end
      test_function func, data
    end
    
    it 'in no trump' do
      logic.set_trump_suits :none
      tests = [
        ['sa', 'sk', :spade, 1],
        ['ca', 'd7', :diamonds, -1],
        ['hq', 'ha', :heart, -1],
        ['c8', 'ca', :heart, 0],
        ['cj', 'c10', :clubs, -1],
        ['h9', 'h10', :heart, -1],
        ['sj', 'sk', :spade, -1],
      ]
      
      compare tests, logic
    end
    
    it 'in all trump' do
      logic.set_trump_suits :all
      tests = [
        ['sa', 'sk', :spade, 1],
        ['ca', 'd7', :diamonds, -1],
        ['hq', 'ha', :heart, -1],
        ['c8', 'ca', :heart, 0],
        ['h9', 'h10', :heart, 1],
        ['sj', 'sk', :spade, 1],
        ['dj', 'cj', :heart, 0],
      ]
      
      compare tests, logic
    end
    
    it 'in trump spade' do
      logic.set_trump_suits :spade
      tests = [
        ['s7', 'da', :diamonds, 1],
        ['da', 'cj', :diamonds, 1],
        ['s9', 's10', :spade, 1],
        ['d8', 's7', :club, -1],
        ['s7', 'sj', :diamonds, -1],
        #['s8', 's10', :heart, -1],
        #['s9', 'sj', :club, 1],
      ]
      
      compare tests, logic
    end
    
    it 'in trump heart' do
      logic.set_trump_suits :heart
      tests = [
        ['hj', 'h9', :heart, 1],
        ['h7', 'da', :diamonds, 1],
        ['da', 'cj', :diamonds, 1],
        ['hj', 'h10', :heart, 1],
        ['d8', 'h8', :clubs, -1],
        ['h7', 'hj', :diamonds, -1],
        ['hj', 'h10', :club, 1],
      ]
      
      compare tests, logic
    end
    
    it 'in trump diamonds' do
      logic.set_trump_suits :diamonds
      tests = [
        ['d7', 'da', :diamonds, -1],
        ['da', 'cj', :spade, 1],
        ['hj', 'h10', :heart, -1],
        ['d8', 'h8', :clubs, 1],
        #['h7', 'hj', :diamonds, -1],
        #['hj', 'h10', :club, 1],
      ]
      
      compare tests, logic
    end
    
    it 'in trump clubs' do
      logic.set_trump_suits :clubs
      tests = [
        ['c9', 'cj', :clubs, -1],
        ['c10', 'c9', :clubs, -1],
        ['hj', 'h10', :heart, -1],
        ['c7', 'sa', :spade, 1],
        ['c8', 'd10', :clubs, 1],
        #['c7', 'c8', :diamonds, -1],
      ]
      
      compare tests, logic
    end
  end
end
require_relative 'short_defines'

describe 'GameMode' do
  include_context "Tests Helper"

  let(:logic) do
    Class.new { include GameMode }.new
  end

  it 'compare card ranks from required suits by given rank order' do
    tests = [
      ['sk', 'sq', :spades, GameMode::TRUMPS_RANKS_ORDER, 1],
      ['sj', 'sa', :spades, GameMode::TRUMPS_RANKS_ORDER, 1],
      ['sj', 'sa', :spades, GameMode::NO_TRUMPS_RANKS_ORDER, -1],
      ['sj', 'sa', :hearts, GameMode::NO_TRUMPS_RANKS_ORDER, 0],
      ['cj', 'sa', :clubs, GameMode::NO_TRUMPS_RANKS_ORDER, 1],
      ['c7', 'dj', :clubs, GameMode::TRUMPS_RANKS_ORDER, 1],
      ['d7', 'h9', :clubs, GameMode::TRUMPS_RANKS_ORDER, 0],
      ['d7', 'h9', :clubs, GameMode::NO_TRUMPS_RANKS_ORDER, 0],
      ['dk', 'dq', :diamonds, GameMode::TRUMPS_RANKS_ORDER, 1],
      ['dk', 'dq', :diamonds, GameMode::NO_TRUMPS_RANKS_ORDER, 1],
      ['d9', 'd10', :diamonds, GameMode::TRUMPS_RANKS_ORDER, 1],
      ['d9', 'd10', :diamonds, GameMode::NO_TRUMPS_RANKS_ORDER, -1],
    ]

    func = lambda { |card1, card2, suit, rank_order| logic.compare_ranks card1, card2, suit, rank_order }
    data = tests.map do |test_case|
      [card(test_case[0]), card(test_case[1])].push *test_case[2..4]
    end
    test_function func, data

    lambda { logic.compare_ranks(card('sa'), card('sq'), :none, GameMode::NO_TRUMPS_RANKS_ORDER) }.should raise_error ArgumentError
  end

  describe 'compare cards' do
    def compare(tests, logic)
      tests.each do |card1, card2, suit, result|
        logic.compare_cards(card(card1), card(card2), suit).should eq(result)#, "test arguments #{[card1, card2, suit, result]} expected #{result}"
      end
    end

    it 'in all trumps' do
      tests = [
        ['sa', 'sk', :spades, 1],
        ['ca', 'd7', :diamonds, -1],
        ['hq', 'ha', :hearts, -1],
        ['c8', 'ca', :hearts, 0],
        ['h9', 'h10', :hearts, 1],
        ['sj', 'sk', :spades, 1],
        ['dj', 'cj', :hearts, 0],
      ]

      compare tests, AllTrumpsMode.new
    end

    it 'in no trumps' do
      tests = [
        ['sa', 'sk', :spades, 1],
        ['ca', 'd7', :diamonds, -1],
        ['hq', 'ha', :hearts, -1],
        ['c8', 'ca', :hearts, 0],
        ['cj', 'c10', :clubs, -1],
        ['h9', 'h10', :hearts, -1],
        ['sj', 'sk', :spades, -1],
      ]

      compare tests, NoTrumpsMode.new
    end

    it 'in trump spades' do
      tests = [
        ['s7', 'da', :diamonds, 1],
        ['da', 'cj', :diamonds, 1],
        ['s9', 's10', :spades, 1],
        ['d8', 's7', :club, -1],
        ['s7', 'sj', :diamonds, -1],
        ['sk', 's9', :diamonds, -1],
        ['s8', 's10', :hearts, -1],
        ['sq', 's10', :hearts, -1],
        ['s9', 'sj', :club, -1],
      ]

      compare tests, SpadesMode.new
    end

    it 'in trump hearts' do
      tests = [
        ['hj', 'h9', :hearts, 1],
        ['h7', 'da', :diamonds, 1],
        ['da', 'cj', :diamonds, 1],
        ['hj', 'h10', :hearts, 1],
        ['d8', 'h8', :clubs, -1],
        ['h7', 'hj', :diamonds, -1],
        ['hj', 'h10', :club, 1],
      ]

      compare tests, HeartsMode.new
    end

    it 'in trump diamonds' do
      tests = [
        ['d7', 'da', :diamonds, -1],
        ['da', 'cj', :spades, 1],
        ['hj', 'h10', :hearts, -1],
        ['d8', 'h8', :clubs, 1],
        ['h7', 'hj', :diamonds, 0],
        ['hj', 'h10', :clubs, 0],
      ]

      compare tests, DiamondsMode.new
    end

    it 'in trump clubs' do
      tests = [
        ['c9', 'cj', :clubs, -1],
        ['c10', 'c9', :clubs, -1],
        ['hj', 'h10', :hearts, -1],
        ['c7', 'sa', :spades, 1],
        ['c8', 'd10', :clubs, 1],
        ['c7', 'c8', :diamonds, -1],
      ]

      compare tests, ClubsMode.new
    end
  end
end

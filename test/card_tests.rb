def card(suit, rank)
  Card.new suit, rank
end

describe "Card" do
  it 'have proper constructor' do
    Card::SUITS.each do |suit|
      Card::RANKS.each do |rank|
        lambda { card(suit, rank) }.should_not raise_error ArgumentError
      end
    end

    lambda { card(:asd, :r19) }.should raise_error ArgumentError
    lambda { card(:spade, :r5) }.should raise_error ArgumentError
    lambda { card(:spades, :r10) }.should raise_error ArgumentError
    lambda { card(:heart, :race) }.should raise_error ArgumentError
    lambda { card(:heart, :rjack) }.should raise_error ArgumentError
  end

  it 'have proper string representation' do
    suits = Card::SUITS.zip ['s', 'h', 'd', 'c']
    ranks = Card::RANKS.zip ['a', 'k', 'q', 'j', '10', '9', '8', '7']

    suits.each do |suit, suit_short|
      ranks.each do |rank, rank_short|
        card(suit, rank).to_s.should eq suit_short + rank_short
      end
    end
  end

  it 'can be equal to other card' do
    Card::SUITS.each do |suit|
      Card::RANKS.each do |rank|
        card(suit, rank).should eq card(suit, rank)
      end
    end

    card(:clubs, :r10).should_not eq card(:heart, :r10)
    card(:spade, :r10).should_not eq card(:spade, :jack)
    card(:spade, :r9).should_not eq card(:spade, :r8)
    card(:diamonds, :r9).should_not eq card(:heart, :r10)
    card(:heart, :queen).should_not eq card(:diamonds, :queen)
  end
end

def hand(*cards)
  Hand.new cards
end

describe "Hand" do
  let (:some_hand) { hand(card(:spade, :r10), card(:heart, :jack),
                          card(:diamonds, :ace), card(:clubs, :r7), card(:clubs, :ace)) }

  it 'initialize properly' do
    lambda { Hand.new }.should_not raise_error StandardError
    lambda { Hand.new card(:spade, :r10), card(:heart, :jack) }.should_not raise_error StandardError

    empty_hand = Hand.new
    empty_hand.cards.size.should eq 0
  end

  it 'have proper string representation(unsorted order by first appearance)' do
    some_hand.to_s.should eq "[s10, hj, da, c7, ca]"
    hand(card(:spade, :r10), card(:heart, :jack)).to_s.should eq "[s10, hj]"
    hand(card(:clubs, :king), card(:diamonds, :queen)).to_s.should eq "[ck, dq]"
  end

  it 'can add cards' do
    card1 = card(:diamonds, :ace)
    card2 = card(:heart, :r10)

    some_hand.add_cards card1, card2
    some_hand.cards.should include card1
    some_hand.cards.should include card2

    card3 = card(:clubs, :r9)
    some_hand.add_cards card3
    some_hand.cards.should include card3
  end

  it 'can remove cards' do
    some_hand.remove_cards card(:spade, :r10)
    some_hand.cards.should_not include card(:spade, :r10)

    some_hand.remove_cards card(:heart, :jack), card(:clubs, :r7)
    some_hand.cards.should_not include card(:heart, :jack), card(:clubs, :r7)
  end
end

describe "BeloteDeck" do
  let(:deck) { BeloteDeck.new }

  it 'initalizes properly' do
    deck.cards.size.should eq 32

    Card::SUITS.each do |suit|
      Card::RANKS.each do |rank|
        deck.cards.should include card(suit, rank)
      end
    end
  end

  it 'can shuffle cards' do
    cards_before = deck.cards
    deck.shuffle
    deck.cards.should_not eq cards_before
  end

  it 'can remove cards from top' do
    last_deck_cards = deck.cards.last(29)
    top_cards = deck.take_top_cards(3)
    deck.cards.size.should eq 29
    deck.cards.should eq last_deck_cards
    top_cards.each { |card| deck.cards.should_not include card }

    last_deck_cards = deck.cards.last(25)
    top_cards += deck.take_top_cards(4)
    deck.cards.size.should eq 25
    deck.cards.should eq last_deck_cards
    top_cards.each { |card| deck.cards.should_not include card }
  end
end

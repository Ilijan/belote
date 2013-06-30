def card(suit, rank)
  Card.new suit, rank
end

describe "Card" do
  it 'have proper constructor' do
    Card::SUITS.product(Card::RANKS).each do |suit, rank|
      lambda { card(suit, rank) }.should_not raise_error ArgumentError
    end

    lambda { card(:asd, :r19) }.should raise_error ArgumentError
    lambda { card(:spades, :r5) }.should raise_error ArgumentError
    lambda { card(:spade, :r10) }.should raise_error ArgumentError
    lambda { card(:hearts, :race) }.should raise_error ArgumentError
    lambda { card(:hearts, :rjack) }.should raise_error ArgumentError
  end

  it 'can construct cards from short abbreviation' do
    suits = Card::SUITS.zip ['s', 'h', 'd', 'c']
    ranks = Card::RANKS.zip ['a', 'k', 'q', 'j', '10', '9', '8', '7']

    suits.product(ranks) do |(suit, suit_short), (rank, rank_short)|
        Card.make_card_short(suit_short + rank_short).to_s.should eq suit_short + rank_short
    end
  end

  it 'have all cards' do
    cards = Card::SUITS.product(Card::RANKS).map { |suit, rank| card(suit, rank) }

    Card.all.size.should eq cards.size

    Card.all.all? { |card| cards.include? card }.should eq true
  end

  it 'have proper string representation' do
    suits = Card::SUITS.zip ['s', 'h', 'd', 'c']
    ranks = Card::RANKS.zip ['a', 'k', 'q', 'j', '10', '9', '8', '7']

    suits.product(ranks) do |(suit, suit_short), (rank, rank_short)|
      card(suit, rank).to_s.should eq suit_short + rank_short
    end
  end

  it 'can be equal to other card' do
    Card::SUITS.product(Card::RANKS) do |suit, rank|
      card(suit, rank).should eq card(suit, rank)
    end

    card(:clubs, :r10).should_not eq card(:hearts, :r10)
    card(:spades, :r10).should_not eq card(:spades, :jack)
    card(:spades, :r9).should_not eq card(:spades, :r8)
    card(:diamonds, :r9).should_not eq card(:hearts, :r10)
    card(:hearts, :queen).should_not eq card(:diamonds, :queen)
  end
end

describe "Hand" do
  def hand(*cards)
    Hand.new cards
  end

  let (:some_hand) { hand(card(:spades, :r10), card(:hearts, :jack),
                          card(:diamonds, :ace), card(:clubs, :r7), card(:clubs, :ace)) }

  it 'initialize properly' do
    lambda { Hand.new }.should_not raise_error StandardError
    lambda { Hand.new [card(:spades, :r10), card(:hearts, :jack)] }.should_not raise_error StandardError

    hand = Hand.new [card(:spades, :r10), card(:hearts, :jack)]
    hand.cards.should eq [card(:spades, :r10), card(:hearts, :jack)]

    empty_hand = Hand.new
    empty_hand.cards.size.should eq 0
  end

  it 'have proper string representation(unsorted order by first appearance)' do
    some_hand.to_s.should eq "[s10, hj, da, c7, ca]"

    hand(card(:spades, :r10), card(:hearts, :jack)).to_s.should eq "[s10, hj]"
    hand(card(:clubs, :king), card(:diamonds, :queen)).to_s.should eq "[ck, dq]"
  end

  it 'can add cards' do
    card1 = card(:diamonds, :ace)
    card2 = card(:hearts, :r10)

    some_hand.add_cards [card1, card2]
    some_hand.cards.should include card1
    some_hand.cards.should include card2

    card3 = card(:clubs, :r9)
    some_hand.add_cards [card3]
    some_hand.cards.should include card3
  end

  it 'can remove cards' do
    some_hand.remove_card card(:spades, :r10)
    some_hand.cards.should_not include card(:spades, :r10)

    some_hand.remove_cards [card(:hearts, :jack), card(:clubs, :r7)]
    some_hand.cards.should_not include card(:hearts, :jack), card(:clubs, :r7)
  end
end

describe "BeloteDeck" do
  let(:deck) { BeloteDeck.new }

  it 'initalizes properly' do
    deck.cards.size.should eq 32

    Card::SUITS.product(Card::RANKS).each do |suit, rank|
      deck.cards.should include card(suit, rank)
    end
  end

  it 'can shuffle cards' do
    cards_before = deck.cards
    deck.shuffle
    deck.cards.should_not eq cards_before
  end

  it 'can remove cards from top' do
    last_deck_cards = deck.cards.drop 3
    top_cards = deck.take_top_cards 3
    deck.cards.size.should eq 29
    deck.cards.should eq last_deck_cards
    top_cards.each { |card| deck.cards.should_not include card }

    last_deck_cards = deck.cards.drop 4
    top_cards += deck.take_top_cards 4
    deck.cards.size.should eq 25
    deck.cards.should eq last_deck_cards
    top_cards.each { |card| deck.cards.should_not include card }
  end

  it 'can be cutted' do
    new_cards = []

    (3..29).each do |cut_size|
      cards_before = deck.cards.clone

      deck.cut_at cut_size
      deck.cards.should_not eq cards_before

      new_cards = cards_before.rotate cut_size
      deck.cards.should eq new_cards
    end

    deck.cut
    deck.cards.should_not eq new_cards
  end
end

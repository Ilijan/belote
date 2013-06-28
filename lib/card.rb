# Hand#possible_announces
# Hand#told_announces
# Hand#tell_announce
require 'announces'

class Card
  SUITS = [:spade, :heart, :diamonds, :clubs]
  #in belote only this ranks are needed
  RANKS = [:ace, :king, :queen, :jack, :r10, :r9, :r8, :r7]
  #SUITS_SHORT = ['s', 'h', 'd', 'c']
  #RANKS_SHORT = ['a', 'k', 'q', 'j', '10', '9', '8', '7']

  def self.make_card_short(short)
    new_suit = SUITS.find { |suit| suit[0] == short[0] }
    new_rank = RANKS.find { |rank| rank.to_s[0..2].include? short[1..2]}
    Card.new new_suit, new_rank
  end

  def self.all
    SUITS.product(RANKS).map { |suit, rank| Card.new suit, rank }
  end

  attr_reader :suit, :rank

  def initialize(suit, rank)
    if not(SUITS.include? suit and RANKS.include? rank)
      raise ArgumentError, "suit: #{suit.to_s} rank: #{rank.to_s}"
    end

    @suit = suit
    @rank = rank
  end

  def to_s
    "%s%s" % [suit.to_s[0], rank[0] == 'r' ? rank[1..2] : rank[0]]
  end

  def ==(other)
    suit == other.suit and rank == other.rank
  end
end

class Hand
  attr_reader :cards

  def initialize(*cards)
    @cards = cards
  end

  def to_s
    "[" + @cards.join(', ') + "]"
  end

  def add_cards(new_cards)
    @cards += new_cards
  end

  def remove_cards(removing_cards)
    @cards -= removing_cards
  end

  def remove_card(card)
    raise ArgumentError "player don't have such card to remove #{card}" unless @cards.include? card

    remove_cards [card]
  end
  
  # def possible_announces
    # Announces.announces self
  # end
  
  # def tell_announce(announce)
    # @told_announces << announce
  # end
  
  # attr_reader :told_announces
end

# class Deck
  # attr_reader :cards

  # def initialize
    # @cards = []
  # end

  # def take_top_cards(number)
    # result = @cards.first number
    # @cards = @cards - result
    # result
  # end
# end

#class BeloteDeck < Deck
class BeloteDeck
  attr_reader :cards

  def initialize(cards = Card.all)
    @cards = cards
  end

  def shuffle
    @cards = @cards.shuffle
  end

  def take_top_cards(number)
    result = @cards.first number
    @cards = @cards - result
    result
  end

  def cut
    cut_size = 3 + rand(@cards.size - 3)          # at least 3 cards to be cut
    first_part = @cards.first(cut_size)
    second_part = @cards.drop(cut_size)
    @cards = second_part + first_part
  end
end

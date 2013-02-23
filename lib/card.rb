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
  
  def add_cards(*new_cards)
    @cards += new_cards
  end
  
  def remove_cards(*removing_cards)
    @cards -= removing_cards
  end
end

class Deck
  attr_reader :cards
  
  def initialize
    @cards = []
  end
  
  def take_top_cards(number)
    result = @cards.first number
    @cards = @cards - result
    result
  end
end

#class BeloteDeck < Deck
class BeloteDeck
  attr_reader :cards

  def initialize
    @cards = []
    
    Card::SUITS.each do |suit|
      Card::RANKS.each do |rank|
        @cards << Card.new(suit, rank)
      end
    end
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
  end
end
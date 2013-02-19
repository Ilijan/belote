class Card
  SUITS = [:spade, :heart, :diamonds, :clubs]
  #in belote only this ranks are needed
  RANKS = [:ace,  :king, :queen, :jack, :r10, :r9, :r8, :r7]

  attr_reader :suit, :rank

  def initialize(suit, rank)
    raise ArgumentError if SUITS.include? suit and RANKS.include? rank
    
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
  
  def add_cards(*new_cards)
    @cards += new_cards
  end
  
  def remove_card()
  
  end
end
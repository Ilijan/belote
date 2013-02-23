require 'card'

module GameMode
  TRUMP_RANKS_ORDER = [:jack, :r9, :ace, :r10, :king, :queen, :r8, :r7]
  NO_TRUMP_RANKS_ORDER = [:ace, :r10, :king, :queen, :jack, :r9, :r8, :r7]

  def set_trump_suits(*trump_suits)
    @trumps = []
    
    return if trump_suits.include? :none
    trump_suits = Card::SUITS if trump_suits.include? :all
    raise ArgumentError if trump_suits.any? { |suit| not Card::SUITS.include? suit }
    
    @trumps.push(*trump_suits)
  end

  def sort_cards_from_suit(hand, suit)
    hand.cards.sort { |x, y| compare_cards(x, y, suit) }
  end

  def max_card_from_hand(hand, required_suit)
    hand.cards.max { |x, y| compare_cards(x, y, required_suit) }
  end

  def trump?(card)
    @trumps.include? card.suit
  end
  
  def compare_ranks(card1, card2, required_suit, ranks_order)
    raise ArgumentError , "suit: #{required_suit}" if not Card::SUITS.include? required_suit
    
    if card1.suit == required_suit and card2.suit == required_suit
      ranks_order.find_index(card2.rank) <=> ranks_order.find_index(card1.rank)
    elsif card1.suit == required_suit and card2.suit != required_suit
      1
    elsif card1.suit != required_suit and card2.suit == required_suit
      -1
    else
      0
    end
  end
  
  def trump_suit?(suit)
    @trumps.include? suit
  end

  def compare_cards(card1, card2, required_suit)
    if trump? card1 and trump? card2
      if card1.suit != required_suit and card2.suit != required_suit and not trump_suit? required_suit
        return TRUMP_RANKS_ORDER.find_index(card2.rank) <=> TRUMP_RANKS_ORDER.find_index(card1.rank)
      end
      compare_ranks card1, card2, required_suit, TRUMP_RANKS_ORDER
    elsif not trump? card1 and not trump? card2
      compare_ranks card1, card2, required_suit, NO_TRUMP_RANKS_ORDER
    elsif trump? card1 and not trump? card2
      1
    elsif not trump? card1 and trump? card2
      -1
    else
      raise RuntimeError "Comparing card1: #{card1.to_s} card2: #{card2.to_s}"
    end
  end
  
  # def compare_cards(card1, card2, required_suit)
    # if trump_suit? required_suit
      # if card1.suit != required_suit and card2.suit != required_suit
        # 0
      # elsif card1.suit == required_suit and card2.suit == required_suit
        
      # end
    # else
    
    # end
  # end
end

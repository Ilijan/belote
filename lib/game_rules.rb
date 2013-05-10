require 'card'

module GameMode
  TRUMP_RANKS_ORDER = [:jack, :r9, :ace, :r10, :king, :queen, :r8, :r7]
  NO_TRUMP_RANKS_ORDER = [:ace, :r10, :king, :queen, :jack, :r9, :r8, :r7]

  def sort_cards_from_suit(hand, suit)
    hand.cards.sort { |x, y| compare_cards(x, y, suit) }
  end

  def max_card_from_hand(hand, required_suit)
    hand.cards.max { |x, y| compare_cards(x, y, required_suit) }
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

  def compare_cards(card1, card2, required_suit)
    nil
  end
end

class AllTrumpMode
  include GameMode

  def compare_cards(card1, card2, required_suit)
    compare_ranks card1, card2, required_suit, TRUMP_RANKS_ORDER
  end
end

class NoTrumpMode
  include GameMode

  def compare_cards(card1, card2, required_suit)
    compare_ranks card1, card2, required_suit, NO_TRUMP_RANKS_ORDER
  end
end

class SuitMode
  include GameMode

  def trump
    nil
  end

  def compare_cards(card1, card2, required_suit)
    result = compare_ranks card1, card2, trump, TRUMP_RANKS_ORDER
    return result if result != 0

    compare_ranks card1, card2, required_suit, NO_TRUMP_RANKS_ORDER
  end
end

class SpadeMode < SuitMode
  include GameMode

  def trump
    :spade
  end
end

class HeartMode < SuitMode
  include GameMode

  def trump
    :heart
  end
end

class DiamondMode < SuitMode
  include GameMode

  def trump
    :diamonds
  end
end

class ClubMode < SuitMode
  include GameMode

  def trump
    :clubs
  end
end

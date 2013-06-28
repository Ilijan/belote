# TODO rename file to modes.rb or game_modes.rb
require 'card'

module GameMode
  TRUMP_RANKS_ORDER = [:jack, :r9, :ace, :r10, :king, :queen, :r8, :r7]
  NO_TRUMP_RANKS_ORDER = [:ace, :r10, :king, :queen, :jack, :r9, :r8, :r7]

  TRUMP_CARD_VALUES = {jack: 20, r9: 14, ace: 11, r10: 10, king: 4, queen: 3, r8: 0, r7: 0}
  NO_TRUMP_CARD_VALUES = {ace: 11, r10: 10, king: 4, queen: 3, jack: 2, r9: 0, r8: 0, r7: 0}

  def sort_cards_from_suit(hand, suit)
    hand.cards.sort { |x, y| compare_cards(x, y, suit) }
  end

  def max_card_from_hand(hand, required_suit)
    hand.cards.max { |x, y| compare_cards(x, y, required_suit) }
  end

  def max_card(cards, required_suit)
    cards.max { |x, y| compare_cards(x, y, required_suit) }
  end

  def compare_ranks(card1, card2, required_suit, ranks_order)
    raise ArgumentError , "suit: #{required_suit}" if not Card::SUITS.include? required_suit

    if card1.suit == required_suit and card2.suit == required_suit
      ranks_order.find_index(card2.rank) <=> ranks_order.find_index(card1.rank) # NOTE: comparing on indexes, bigger card smaller index
    elsif card1.suit == required_suit and card2.suit != required_suit
      1
    elsif card1.suit != required_suit and card2.suit == required_suit
      -1
    else
      0
    end
  end

  def compare_cards(card1, card2, required_suit)
    raise "Not implemeted"
  end

  # def card_value(card)
    # raise "Not implemeted"
  # end
end

module MatchPoints
  # GAME_POINTS = {alltrump: 26,
                 # notrump:  26,
                 # spade:    16,
                 # heart:    16,
                 # diamond:  16,
                 # club:     16}

  VALAT_BONUS = 90

  def round_limit
    raise "Not implemeted"
  end

  def last_digit(point)
    point % 10
  end

  def round_up?(point)
    last_digit(point) >= round_limit
  end

  def round(point)
    point += 5 if round_up?(point)
    (point / 10.0).round
  end

  def match_points(points)
    result = {}

    result[:north_south_team] = round points[:north_south_team]
    result[:east_west_team]   = round points[:east_west_team]

    # REVIEW: roundin down
    if last_digit(points[:north_south_team]) == round_limit and
       last_digit(points[:east_west_team])== round_limit and
       points[:north_south_team] != points[:east_west_team]     # not in hanging case
      result[points.max { |a, b| a.last <=> b.last }.first] -= 1
    end

    result
  end
end

class DoubleMode < BasicObject
  def initialize(mode)
    @mode = mode
  end

  def method_missing(name, *args, &block)
    super unless @mode.respond_to? name
    @mode.public_send name, *args, &block
  end
end

class RedoubleMode < DoubleMode
end

class AllTrumpMode
  include GameMode
  include MatchPoints

  def compare_cards(card1, card2, required_suit)
    compare_ranks card1, card2, required_suit, TRUMP_RANKS_ORDER
  end

  def card_value(card)
    TRUMP_CARD_VALUES[card.rank]
  end

  def trump?(card)
    true
  end

  def round_limit
    4
  end

  def to_sym
    :alltrump
  end
end

class NoTrumpMode
  include GameMode
  include MatchPoints

  def compare_cards(card1, card2, required_suit)
    compare_ranks card1, card2, required_suit, NO_TRUMP_RANKS_ORDER
  end

  def card_value(card)
    NO_TRUMP_CARD_VALUES[card.rank]
  end

  def trump?(card)
    false
  end

  def round(point)
    super point * 2
  end

  def round_limit
    5
  end

  def to_sym
    :notrump
  end
end

class SuitMode
  include GameMode
  include MatchPoints

  alias_method :to_sym, :trump

  def trump
    raise "Not implemeted"
  end

  def compare_cards(card1, card2, required_suit)
    result = compare_ranks card1, card2, trump, TRUMP_RANKS_ORDER
    return result if result != 0

    compare_ranks card1, card2, required_suit, NO_TRUMP_RANKS_ORDER
  end

  def card_value(card)
    if trump?
      TRUMP_CARD_VALUES[card.rank]
    else
      NO_TRUMP_CARD_VALUES[card.rank]
    end
  end

  def trump?(card)
    card.suit == trump
  end

  def round_limit
    6
  end
end

class SpadeMode < SuitMode
  def trump
    :spade
  end
end

class HeartMode < SuitMode
  def trump
    :heart
  end
end

class DiamondMode < SuitMode
  def trump
    :diamonds
  end
end

class ClubMode < SuitMode
  def trump
    :clubs
  end
end

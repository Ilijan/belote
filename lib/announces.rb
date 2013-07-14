require 'card'
# Player#possible_announces
# Player#told_announces
# Player#tell_announce

module Announces
  extend self # REVIEW: should it stay like that? or mixin in Hand class

  ALL = [:belote, :therta, :quarta, :quinta, :carre]  #:carre_jacks, :carre_nines,
  CARD_ORDER = [:ace, :king, :queen, :jack, :r10, :r9, :r8, :r7]
  VALUES = {belote: 20,
            therta: 20,
            quarta: 50,
            quinta: 100,
            carre: 100,
            carre_nines: 150,
            carre_jacks: 200}

  # Returns sequence of cards of given length which are in announce card order.
  # The sequence is sorted by first appearence in the hand.
  def sequence(hand, length)
    Card::SUITS.each do |suit|
      hand_ranks = hand.cards.select { |card| card.suit == suit }.map(&:rank)

      next if hand_ranks.size < length

      CARD_ORDER.each_cons(length) do |slice|
        if (hand_ranks & slice).size == length
          return hand.cards.select { |card| card.suit == suit and slice.include? card.rank }
          #return slice.map { |rank| Card.new suit, rank }   #for sorted result
        end
      end
    end
    []
  end

  def find_all_sequences(hand, length)
    sequence_cards = sequence(hand, length)
    result = []
    if sequence_cards.size > 0
      result = [sequence_cards]
      result += find_all_sequences Hand.new(hand.cards - sequence_cards), length
    end
    result
  end

  def find_belote(hand)
    result = []
    Card::SUITS.each do |suit|
      belote_cards = hand.cards.select { |card| card.suit == suit and (card.rank == :king or card.rank == :queen) }
      result += [belote_cards] if belote_cards.size == 2
    end
    result.size > 0 ? result.unshift(:belote) : []
  end

  def find_therta(hand)
    result = find_all_sequences(hand, 3)
    result.size > 0 ? result.unshift(:therta) : []
  end

  def find_quarta(hand)
    result = find_all_sequences(hand, 4)
    result.size > 0 ? result.unshift(:quarta) : []
  end

  def find_quinta(hand)
    # only one quinta can be found
    quinta_cards = sequence(hand, 5)
    quinta_cards.size > 0 ? [:quinta, quinta_cards] : []
  end

  def find_carre(hand)
    hand_ranks = hand.cards.map(&:rank)
    carres = Card::RANKS[0..-3].select { |rank| hand_ranks.count(rank) == 4 }
    carres.size > 0 ? carres.unshift(:carre) : []
  end

  def announces(hand)
    result = []
    belote = find_belote(hand)
    result << belote if belote.size > 0
    new_hand = hand

    [:find_carre, :find_quinta, :find_quarta, :find_therta, :find_belote].each do |func|
      found_announces = public_send(func, new_hand)
      if found_announces.size > 0
        new_hand = Hand.new(new_hand.cards - found_announces.drop(1).flatten)
        result << found_announces
      end
    end

    result
  end

  def evaluate(announces)
    # Hack
    bonus = announces.select { |announce| announce.first == :carre }.flatten.map do |rank|
      case rank
      when :jack then 100
      when :r9   then 50
      else            0
      end
    end.reduce(:+) || 0

    bonus + (announces.map(&:first).map { |announce| Announces::VALUES[announce] }.reduce(:+) || 0)
  end
end

module CompareAnnounces
  extend self # REVIEW: should it stay like that?

  SEQUENTIAL_ANNOUNCES_ORDER = [:therta, :quarta, :quinta]

  def sequential_announce?(announce)
    SEQUENTIAL_ANNOUNCES_ORDER.include? announce
  end

  # def check(announce1, announce2, types = nil, msg = nil)
    # type1 = announce1.first
    # type2 = announce2.first

    # if type1 == type2
      # if types and not types.include?(type1)
        # if msg
          # raise ArgumentError, "#{msg}: #{type1}, #{type2}"
        # else
          # raise ArgumentError, "Not of type #{types}: #{type1}, #{type2}"
        # end
      # end
    # else
      # raise ArgumentError, "Different announce types: #{type1}, #{type2}"
    # end

    # true
  # end

  def compare_ranks(card1, card2) # NOTE: comparing on indexes, bigger card smaller index
    Announces::CARD_ORDER.find_index(card2.rank) <=> Announces::CARD_ORDER.find_index(card1.rank)
  end

  def max_rank(cards_seq)
    cards_seq.max { |card1, card2| compare_ranks card1, card2 }.rank
  end

  # def comp_thertas(announce1, announce2) # same for others
    # return false unless announce1.first == :therta and announce1.first == announce2.first

    # # REFACTOR code repetition
    # max_rank1 = announce1.drop(1).map(&:max_rank).max { |rank1, rank2| compare_ranks rank1, rank2 }
    # max_rank2 = announce2.drop(1).map(&:max_rank).max { |rank1, rank2| compare_ranks rank1, rank2 }

    # compare_ranks max_rank1, max_rank2
  # end

  def comp_sequence(seq_announce1, seq_announce2)
    # check seq_announce1, seq_announce2, SEQUENTIAL_ANNOUNCES_ORDER, "Not sequence announce"

    type1 = seq_announce1.first
    type2 = seq_announce2.first

    unless sequential_announce?(type1) and sequential_announce?(type2)
      raise ArgumentError, "Not sequence announce: #{type1} #{type2}"
    end

    # NOTE: comparing by index, bigger index bigger announce
    comp = SEQUENTIAL_ANNOUNCES_ORDER.find_index(type1) <=> SEQUENTIAL_ANNOUNCES_ORDER.find_index(type2)
    return comp if comp != 0

    # REFACTOR: code repetition
    max_rank1 = seq_announce1.drop(1).map(&:max_rank).max { |rank1, rank2| compare_ranks rank1, rank2 }
    max_rank2 = seq_announce2.drop(1).map(&:max_rank).max { |rank1, rank2| compare_ranks rank1, rank2 }

    compare_ranks max_rank1, max_rank2
  end

  def comp_carre(carre1, carre2)
    carres_order = [:jack, :r9, :ace, :king, :queen, :r10]
    type1 = carre1.first
    type2 = carre2.first

    raise ArgumentError, "Not carres: #{type1} #{type2}" unless type1 == :carre and type2 == :carre
    
    # check carre1, carre2, [:carre]

    # REFACTOR: code repetition
    max_rank1 = carre1.drop(1).map(&:max_rank)
    max_rank2 = carre2.drop(1).map(&:max_rank)

    carres_order.find_index(max_rank1) <=> carres_order.find_index(max_rank2)
  end

  # FIXME: code repetition #comp_sequence_announces and #comp_carre_announces
  def comp_sequence_announces(announce1, announce2)
    seq_announce1 = announce1[0] + announce1.drop(1).map { |seq| seq.drop 1 }
    seq_announce2 = announce2[0] + announce2.drop(1).map { |seq| seq.drop 1 }

    comp_sequence(seq_announce1, seq_announce2)
  end

  def comp_carre_announces(carres1, carres2)
    return 1 if carres2.size == 0
    return -1 if carres1.size == 0

    carres1 = carres1[0] + carres1.drop(1).map { |seq| seq.drop 1 }
    carres2 = carres2[0] + carres2.drop(1).map { |seq| seq.drop 1 }

    comp_carres(carres1, carres2)
  end

  def comp_announces(announce1, announce2)
    type1 = announce1.first
    type2 = announce2.first

    case
    when (sequential_announce?(type1) and
          sequential_announce?(type2))                    # comparing 2 sequence announces
      comp_sequence_announces(announce1, announce2)
    when types.count(:carre) == 2                         # comparing 2 carres
      comp_carre_announces(announce1, announce2)
    else                                                  # comparing different announces (sequence, carre, belote)
      raise ArgumentError, "Different announce tipes: #{type1}, #{type2}"
    end
  end
end
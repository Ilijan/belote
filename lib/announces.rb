require 'card'
# Player#possible_announces
# Player#told_announces
# Player#tell_announce

module Announces
  ALL_ANNOUNCES = [:belote, :therta, :quarta, :quinta, :carre]  #:carre_jacks, :carre_nines,
  ANNOUNCES_CARD_ORDER = [:ace, :king, :queen, :jack, :r10, :r9, :r8, :r7]

  def sequence(hand, length)
    Card::SUITS.each do |suit|
      hand_ranks = hand.cards.select { |card| card.suit == suit }.map(&:rank)

      next if hand_ranks.size < length

      ANNOUNCES_CARD_ORDER.each_cons(length) do |slice|
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
      result += find_all_sequences Hand.new(*(hand.cards - sequence_cards)), length
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
    carres = []
    Card::RANKS[0..-3].each_with_object(carres) do |rank, memo|
      if hand_ranks.count(rank) == 4
        memo << rank
      end
    end
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
        new_hand = Hand.new(*(new_hand.cards - found_announces.drop(1).flatten))
        result << found_announces
      end
    end

    result
  end
end

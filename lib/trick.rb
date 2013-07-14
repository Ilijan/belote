require 'card'
require 'belote_table'
require 'game_rules'
require 'announces'
require 'points'

class Trick
  attr_reader :first_player

  def initialize(players, first_player, mode, last_trick = false)
    @players = BelotePlayers.new players, first_player, 1
    @first_player = first_player
    @mode = mode
    @last_trick = last_trick

    @played_cards = {}
    @stats = {:north_south_team  => {points: 0, announces: []},
              :east_west_team    => {points: 0, announces: []}}
  end

  def cards
    @played_cards
  end

  def last_trick?
    @last_trick
  end

  def player_on_turn
    @players.player_on_turn
  end

  def next_player_on_turn
    @players.next_player_on_turn
  end

  def player_on_turn_position
    @players.player_on_turn_position
  end

  # REVIEW: should it be in class Hand? or in Announces
  def have_belote?(player_position, card)
    return false if @mode.instance_of? NoTrumpsMode

    @players.player_on_position(player_position).hand.cards.select do |c|
      c.suit == card.suit and [:king, :queen].include? c.rank
    end.size == 2 and @mode.trump?(card.suit)
  end

  def play_card(player_position, card, belote = false)
    @players.player_on_position(player_position).hand.remove_card card

    @played_cards[player_position] = card

    if belote
      team = BelotePlayers.player_team_sym player_position
      @stats[team][:announces] << [:belote, card, Card.new(card.suit, ([:king, :queen] - [card.rank]).first)]
      # @stats[team][:announces] << [:belote]
    end
  end

  def player_on_turn_play_card(card)
    play_card player_on_turn_position, card
  end

  def winner
    max_card = @mode.max_card @played_cards.values, @played_cards[first_player].suit
    @played_cards.invert[max_card]
    # @played_cards.select { |player, card| max_card == card }.keys[0]   # FIXME: check line above for hashing cards
  end

  # def winner!(played_cards, required_suit, mode)
    # max_card = mode.max_card played_cards.values, required_suit
    # played_cards.invert[max_card]
  # end

  def trick_card_points
    @played_cards.values.map { |card| @mode.card_value card }.reduce(:+)
  end

  def announces_points(team1_announces, team2_announces)
    return [0, 0] if @mode.instance_of? NoTrumpsMode

    [Announces.evaluate(team1_announces.select { |announce| announce.first == :belote }),
     Announces.evaluate(team2_announces.select { |announce| announce.first == :belote })]
  end

  # sums card values and belotes, adds 10 points to winning team points if this is last trick
  def points
    if @stats[:north_south_team][:points] == 0 and @stats[:east_west_team][:points] == 0
      @stats[BelotePlayers.player_team_sym(winner)][:points] += trick_card_points
      @stats[BelotePlayers.player_team_sym(winner)][:points] += 10 if last_trick?

      result_announce_points = announces_points(@stats[:north_south_team][:announces],
                                                @stats[:east_west_team][:announces])

      @stats[:north_south_team][:points] += result_announce_points[0]
      @stats[:east_west_team][:points] += result_announce_points[1]
    end

    Points.new({:north_south_team => @stats[:north_south_team][:points],
                :east_west_team   => @stats[:east_west_team][:points]})
  end
end

class FirstTrick < Trick
  def announces(player_position)
    return [] if @mode.instance_of? NoTrumpsMode

    Announces.announces @players.player_on_position(player_position).hand
  end

  def declare_announce(player_on_position, announce)
    return if @mode.instance_of? NoTrumpsMode    # REVIEW: maybe raise exception

    team = BelotePlayers.player_team_sym player_on_position
    @stats[team][:announces] << announce
  end

  def player_on_turn_announces
    announces player_on_turn_position
  end

  def player_on_turn_declare_announce(announce)
    declare_announce player_on_position, announce
  end

  # FIXME: Too long
  def announces_points(team1_announces, team2_announces)
    return [0, 0] if @mode.instance_of? NoTrumpsMode

    team1_points = 0
    team2_points = 0

    # Evaluates belotes
    belote_points = super
    team1_points += belote_points[0]
    team2_points += belote_points[1]
    
    pp [team1_points, team2_points]

    # Evaluates seqs
    team1_seq_announces = team1_announces.select do |announce|
      CompareAnnounces.sequential_announce? announce.first
    end
    team2_seq_announces = team2_announces.select do |announce|
      CompareAnnounces.sequential_announce? announce.first
    end
    
    pp [team1_points, team2_points]

    case CompareAnnounces.comp_sequence_announces(team1_seq_announces,
                                                  team2_seq_announces)
    when 1
      team1_points += Announces.evaluate team1_seq_announces
    when -1
      team2_points += Announces.evaluate team1_seq_announces
    end

    # Evaluates carres
    team1_carres_announces = team1_announces.select { |announce| announce.first == :carre }
    team2_carres_announces = team2_announces.select { |announce| announce.first == :carre }

    case CompareAnnounces.comp_carre_announces(team1_carres_announces,
                                               team2_carres_announces)
    when 1
      team1_points += Announces.evaluate team1_carres_announces
    when -1
      team2_points += Announces.evaluate team1_seq_announces
    end

    # Result
    [team1_points, team2_points]
  end
end
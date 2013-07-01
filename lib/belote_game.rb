# TODO: split file into belote_game.rb, bit_phase.rb and deal_game.rb

require 'card'
require 'belote_table'
require 'game_rules'
require 'trick'
require 'points'

class BeloteGame
  # Inner API previous_deal setter/getter
  attr_accessor :first_player#, :previous_deal
  attr_reader :players

  def initialize(players = {}, first_player = nil)
    @players = players
    @first_player = first_player
    @players_succession = BelotePlayers.new players, @first_player

    @deck = BeloteDeck.new
    @deck.shuffle

    @previous_deal = nil

    @hanging_points = Points.zeros
    @result_points = Points.zeros
  end

  def set_player_on_position(position, player)
    BelotePlayers.check position

    @players[position] = player
  end

  def set_south_player(player)
    set_player_on_position :south, player
  end

  def set_north_player
    set_player_on_position :north, player
  end

  def set_west_player
    set_player_on_position :west, player
  end

  def set_east_player
    set_player_on_position :east, player
  end

  # Inner API
  def save_to_hanging_points(points, team_receiving_points)
    @hanging_points.add points, team_receiving_points
  end

  # Inner API
  def add_to_result(points, team_receiving_points = nil)
    @result_points.add points, team_receiving_points
  end

  # Inner API
  def take_and_clear_hanging_points
    @result = @hanging_points

    @hanging_points = nil     # or Points.zeros

    @result
  end

  # Inner API
  def first_deal?
    @previous_deal.nil?
  end

  # Inner API
  def create_next_deal(players_succession, deck)
    player_on_turn = players_succession.player_on_turn
    players_succession.next_player_on_turn

    deck.cut
    DealGame.new players_succession.to_hash, player_on_turn, deck
  end

  # REVIEW: with valat team cannot win
  def end_game?
    not @previous_deal.valat? and @result_points.to_hash.values.any? { |points| points >= 151 }
  end

  def winner_team
    return @result_points.team_with_max_points if end_game?
  end

  def next_deal
    return nil if end_game?   # REVIEW: raise exception?

    # REVIEW: hagning points write down points for the team not on the bid
    unless first_deal?
      if not @previous_deal.hanging?
        add_to_result take_and_clear_hanging_points
        add_to_result @previous_deal.points
      else
        add_to_result @previous_deal.points, @previous_deal.opposing_team
        save_to_hanging_points @previous_deal.points, @previous_deal.bid_said_by_team
      end
    end

    @previous_deal = create_next_deal(@players_succession,
                                      @previous_deal.assemble_deck)
    @previous_deal
  end

  def score
    @result_points.to_hash
  end
end

class BidPhase
  BIDS_ORDER = [:alltrumps, :notrumps, :spades, :hearts, :diamonds, :clubs]
  ALL_BIDS = [:pass, :redouble, :double, :alltrumps, :notrumps, :spades, :hearts, :diamonds, :clubs]
  BIDS_MODES = {pass: nil,
                redouble: nil,
                double: nil,
                alltrumps: AllTrumpsMode,
                notrumps: NoTrumpsMode,
                spades: SpadesMode,
                hearts: HeartsMode,
                diamonds: DiamondsMode,
                clubs: ClubsMode}

  attr_reader :won_bid, :bid_said_by

  def initialize(players, first_player)
    @players = BelotePlayers.new players, first_player
    @won_bid = nil
    @bid_said_by = nil
    @is_double = false
    @is_redouble = false
    @pass_count = 0
  end

  def double?
    @is_double
  end

  def redouble?
    @is_redouble
  end

  def end_of_bidding?
    (won_bid.nil? and @pass_count == 4) or
    (won_bid and @pass_count == 3) # or
    #(won_bid == :alltrumps and redouble?)
  end

  def player_on_turn
    @players.player_on_turn
  end

  def next_player_on_turn
    raise StopIteration if end_of_bidding?

    @players.next_player_on_turn
  end

  def player_on_turn_position
    @players.player_on_turn_position
  end

  def clear_doubling# (double_redouble = nil)
    # case double_redouble
    # when :double
      # @is_double = false
    # when :redouble
      # @is_redouble = false
    # when nil
      # @is_double = false
      # @is_redouble = false
    # else
      # raise "invalid mode #{mode}"
    # end
    @is_double = false
    @is_redouble = false
  end

  # Does not check if bid is lower than current won_bid and who bids what
  def set_bid(player_on_position, bid)
    raise ArgumentError, "invalid bid #{bid}" unless ALL_BIDS.include? bid
    # raise ArgumentError, "impossible bid #{bid}" unless possible_bids.include? bid

    if bid == :pass
      @pass_count += 1
      return
    end

    if @won_bid.nil? and [:double, :redouble].include? bid
      raise ArgumentError, "doubling nothing: #{bid}"
    end

    if bid == :double
      @is_double = true
      @bid_said_by = player_on_position
    elsif bid == :redouble
      @is_double = false
      @is_redouble = true
      @bid_said_by = player_on_position
    else
      @won_bid = bid
      @bid_said_by = player_on_position
      clear_doubling
    end

    @pass_count = 0
  end

  def possible_bids(player_on_position)
    bids = [:pass]

    if @won_bid and not BelotePlayers.player_team(@bid_said_by).include? player_on_position
      bids += if double?
                [:redouble]
              elsif redouble?
                []
              else
                [:redouble, :double]
              end
    end

    index = BIDS_ORDER.index(@won_bid)
    bids += (index) ? BIDS_ORDER.take(index) : BIDS_ORDER

    bids
  end

  def player_on_turn_possible_bids
    possible_bids @players.player_on_turn_position
  end

  def player_on_turn_set_bid(bid)
    set_bid @players.player_on_turn_position, bid
  end

  def doubling
    return :double if double?
    return :redouble if redouble?
  end
end

class DealGame
  attr_reader :mode, :first_player

  def initialize(players, first_player, deck)
    @players = players
    @first_player = first_player
    @players_succession = BelotePlayers.new players, first_player

    @bid_phase = BidPhase.new @players, @first_player
    @deck = deck
    @mode = nil

    @tricks = []
    @current_trick_index = 0

    @points = Points.zeros
  end

  def deal_first_five_cards
    deal_cards_to_all 3
    deal_cards_to_all 2
  end

  def deal_last_three_cards
    deal_cards_to_all 3
  end

  def deal_cards_to_all(count)
    # @players.each_pair do |position, player|
      # deal_cards player, count
    # end
    deal_cards @players_succession.player_on_turn, count
    deal_cards @players_succession.next_player_on_turn, count
    deal_cards @players_succession.next_player_on_turn, count
    deal_cards @players_succession.next_player_on_turn, count
    @players_succession.next_player_on_turn
  end

  def deal_cards(player, count)
    player.hand.add_cards @deck.take_top_cards count
  end

  def bidding
    @bid_phase
  end

  def set_mode(mode, doubling = nil)
    unless BidPhase::BIDS_MODES[mode]
      raise ArgumentError, "not valid mode #{mode}"
    end

    @mode = case doubling
            when :double
              DoubleMode.new BidPhase::BIDS_MODES[mode]
            when :redouble
              RedoubleMode.new BidPhase::BIDS_MODES[mode]
            else
              BidPhase::BIDS_MODES[mode].new
            end
  end

  def set_won_bid_mode
    return false if @bid_phase.won_bid.nil?

    set_mode @bid_phase.won_bid, @bid_phase.doubling

    true
  end

  # OPTIMIZE: Maybe some abstraction like enumerable for all those methods next_... current_...
  def current_trick
    @tricks[@current_trick_index]
  end

  def first_trick
    if @current_trick_index == 0
      next_trick
    else
      raise "it's not time for first trick"
    end
  end

  def next_trick
    new_trick = case @current_trick_index
                when 0
                  FirstTrick.new @players, first_player, @mode
                when (1..6)
                  # OPTIMIZE
                  Trick.new @players, current_trick.winner, @mode
                when 7
                  Trick.new @players, current_trick.winner, @mode, true
                when 8
                  raise "No more tircks to play"    # REVIEW: return nil
                end

    @tricks << new_trick
    @current_trick_index += 1

    new_trick
  end

  def bid_said_by_team
    BelotePlayers.player_team_sym @mode.bid_said_by
  end

  def opposing_team
    BelotePlayers.opposing_team bid_said_by_team
  end

  # def inside?
    # points.inside? bid_said_by_team
  # end

  def hanging?
    points.hanging?
  end

  def tricks_of_team(team)
    team_players = BelotePlayers.team_players team

    @tricks.select { |trick| team_players.include? trick.winner }
  end

  def north_south_tricks
    tricks_of_team :north_south_team
  end

  def east_west_tricks
    tricks_of_team :east_west_team
  end

  def valat?
    north_south_tricks.size == 0 or east_west_tricks.size == 0
  end

  # takes deal points
  # returns match points or final score points
  # REVIEW: maybe, some method abstraction in the DoubleMode and RedoubleMode
  def doubling_points(points, mode)
    result = mode.round points.all
    result *= 2 if @mode.instance_of? DoubleMode
    result *= 4 if @mode.instance_of? RedoubleMode

    result
  end

  def tricks_points(tricks)
    tricks.map(&:points).reduce(Points.zeros) { |memo, points| memo.add points }
  end

  # TODO: caching/memorizing result
  # REFACTOR: ...
  # REVIEW: case valat
  # REVIEW: points rounding
  # REVIEW: hanging
  # REVIEW: can the core part of the logic of the method move in Modes classes in #match_points ?
  #   Then the body of this method will look like
  #   @mode.match_points tricks_points @tricks
  def points
    deal_points = tricks_points @tricks

    if not deal_points.inside? bid_said_by_team
      deal_points.add_points_to(bid_said_by_team, MatchPoints::VALAT_BONUS) if valat?

      if not @mode.is_a? DoubleMode
        @mode.match_points deal_points
      else
        Points.zeros[bid_said_by_team] = doubling_points deal_points, @mode
      end
    elsif deal_points.inside? bid_said_by_team
      deal_points.add_points_to(opposing_team, MatchPoints::VALAT_BONUS) if valat?

      Points.zeros[opposing_team] = doubling_points deal_points, @mode
    elsif deal_points.hanging?
      if not @mode.is_a? DoubleMode
        @mode.match_points deal_points
      else
        doubled_points = doubling_points deal_points, @mode

        result = Points.zeros
        result[bid_said_by_team] = doubled_points / 2
        resutl[opposing_team] = doubled_points / 2

        result
      end
    end
  end

  # Cards won by one team are added on top of the others to assemble new deck for next deal
  # This is not deck cut
  def assemble_deck
    cards = (north_south_tricks + east_west_tricks).map(&:cards)
    BeloteDeck.new cards
  end
end

__END__
# module HavePlayers#player_on_turn, #next_player_on_turn, ?#@players = {}?, #PLAYERS_ORDINANCE
# class BidPhase mixin HavePlayers, #set_game_mode #possible_bids #game_mode
belote = BeloteGame.new
belote.set_player_on_position ...
belote.first_player = position
deal = belote.next_deal
deal.deal_first_five_cards
bids = deal.bidding

bids.player_on_turn               # first bid
modes = bids.possible_bids
bids.set_bid modes[x..y]

bids.next_player_on_turn          # second bid
modes = bids.possible_bids
bids.set_bid modes[x..y]

bids.next_player_on_turn          # third bid
modes = bids.possible_bids
bids.set_bid modes[x..y]

bids.next_player_on_turn          # fourth bid
modes = bids.possible_bids
bids.set_bid modes[x..y]

unless deal.set_won_bid_mode  # bids.won_bid
  # All players said pass go to next deal
end

trick = deal.next_trick           #FirstTrick

trick.announces(trick.player_on_turn)
trick.play_card(trick.player_on_turn, card)
trick.player_on_turn_announces
trick.player_on_turn_declare_announce(announce)
trick.player_on_turn_play_card(card)
# second third fourth

trick = deal.next_trick
# ...

p = deal.points


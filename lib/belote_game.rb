require 'card'
require 'belote_table'
require 'game_rules'
require 'trick'

class BeloteGame
  # Inner API previous_deal setter/getter
  attr_accessor :first_player#, :previous_deal
  attr_reader :players

  def initialize(players = {}, first_player = nil)
    @players = players
    @first_player = first_player

    @deck = BeloteDeck.new
    @deck.shuffle

    @previous_deal = nil

    @result_points = {:north_south_team => 0,
                      :east_west_team   => 0}
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
  def sum_points(points1, points2)
    points1.merge(points2) { |key, oldval, newval| newval + oldval }
  end

  # Inner API
  def save_points(result_points, points_to_save, team_receiving_points = nil)
    if team_receiving_points
      opposing_team = BelotePlayers.opposing_team team_receiving_points
      points_to_save = {team_receiving_points => points_to_save[opposing_team],
                        opposing_team         => 0}
    end
    sum_points result, points_to_save
  end

  # Inner API
  def save_to_hanging_points(points, team_receiving_points)
    # points = points.clone
    # points[bid_said_by_team] = 0
    # @hanging_points = sum_points @hanging_points, points
    save_points @hanging_points,
                @previous_deal.points,
                @previous_deal.bid_said_by_team
  end

  # Inner API
  def add_to_result(points, team_receiving_points = nil)
    @result_points = save_points @result_points, points, team_receiving_points
  end

  # Inner API
  def take_and_clear_hanging_points
    @result = @hanging_points

    @hanging_points = {}

    @result
  end

  # Inner API
  def first_deal?
    @previous_deal.nil?
  end

  # Inner API
  def create_next_deal(players, current_player, deck)
    player_on_turn = first_deal? ? first_player : BelotePlayers.player_after current_player

    deck.cut
    DealGame.new players, player_on_turn, deck
  end

  # FIXME: with valat team cannot win
  def end_game?
    not @previous_deal.valat? and @result_points.values.any? { |points| points >= 151 }
  end

  def winner_team
    return @result_points.max { |a, b| a.last <=> b.last }.first if end_game?
  end

  def next_deal
    return nil if end_game?

    # REVIEW: hagning points write down points for the team not on the bid
    unless first_deal
      if not @previous_deal.hanging? @previous_deal.points
        add_to_result take_and_clear_hanging_points
        add_to_result @previous_deal.points
      else
        add_to_result @previous_deal.points, @previous_deal.opposing_team
        save_to_hanging_points @previous_deal.points, @previous_deal.bid_said_by_team
      end
    end

    @previous_deal = create_next_deal(players,
                                      @previous_deal.first_player,
                                      @previous_deal.assemble_deck)
    @previous_deal
  end
end

class BidPhase
  BIDS_ORDER = [:alltrump, :notrump, :spade, :heart, :diamond, :club]
  # ALL_BIDS = [:pass, :redouble, :double, :alltrump, :notrump, :spade, :heart, :diamond, :club]
  BIDS_MODES = {pass: nil,
                redouble: nil,
                double: nil,
                alltrump: AllTrumpMode,
                notrump: NoTrumpMode,
                spade: SpadeMode,
                heart: HeartMode,
                diamond: DiamondMode,
                club: ClubMode}

  attr_reader :won_bid, :bid_said_by,:double?, :redouble?

  def initialize(players, first_player)
    @players = BelotePlayers.new players, first_player, 1
    @won_bid = nil
    @bid_said_by = nil
    @double? = false
    @redouble? = false
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

  def set_bid(player_on_position, bid)
    # raise ArgumentError "invalid bid #{bid}" unless ALL_BIDS.include? bid
    # raise ArgumentError "impossible bid #{bid}" unless possible_bids.include? bid

    return if bid == :pass

    if bit == :double
      @double? = true
      @bid_said_by = player_on_position
    elsif bit == :redouble
      @double? = false
      @redouble? = true
      @bid_said_by = player_on_position
    else
      @won_bid = bid
      @bid_said_by = player_on_position
    end
  end

  def possible_bids(player_on_position)
    bids = [:pass]

    if @won_bid and not BelotePlayers.player_team(@bid_said_by).include? player_on_position
      bids += if double?
                [:redouble]
              elsif :redouble?
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

  def double_redouble
    return :double if double?
    return :redouble if redouble?
  end
end

# FIXME: make methods with no parameters #max_points, #inside?, #hanging?, ... etc
# OPTIMIZE: some abstraction about points which maybe have following methods
#   DealGame#team_with_max_points, DealGame#inside?, DealGame#hanging?, BeloteGame#sum_points,
#   ... etc
class DealGame
  attr_reader :mode, :first_player

  def initialize(players, first_player, deck)
    @players = players
    @first_player = first_player

    @bid_phase = BidPhase.new @players, @first_player
    @deck = deck
    @mode = nil

    @tricks = [FirstTrick.new(@players, @first_player)]
    @current_trick_index = 0
  end

  def deal_first_five_cards
    deal_cards_to_all 5
  end

  def deal_last_three_cards
    deal_cards_to_all 3
  end

  def deal_cards_to_all(count)
    @players.each_pair do |position, player|
      deal_cards player, count
    end
  end

  def deal_cards(player, count)
    player.hand.add_cards @deck.take_top_cards count
  end

  def bidding
    @bid_phase
  end

  def set_mode(mode, double_redouble = nil)
    unless BidPhase::BID_MODES[mode]
      raise ArgumentError "not valid mode #{mode}"
    end

    @mode = case double_redouble
            when :double
              DoubleMode.new BidPhase::BID_MODES[mode]
            when :redouble
              RedoubleMode.new BidPhase::BID_MODES[mode]
            else
              BidPhase::BID_MODES[mode].new
            end
  end

  def set_won_bid_mode
    return false if @bid_phase.won_bid.nil?

    set_mode @bid_phase.won_bid, @bid_phase.double_redouble

    true
  end

  # OPTIMIZE: Maybe some abstraction like enumerable for all those methods next_... current_...
  def current_trick
    @tricks[@current_trick_index]
  end

  def next_trick
    new_trick = case @current_trick_index
                when 0
                  FirstTrick.new @players, BelotePlayers.player_after(current_trick.first_player), @mode
                when (1..6)
                  # OPTIMIZE
                  Trick.new @players, BelotePlayers.player_after(current_trick.first_player), @mode
                when 7
                  Trick.new @players, BelotePlayers.player_after(current_trick.first_player), @mode, true
                when 8
                  raise "No more tircks to play"
                end

    @tricks << new_trick
    @current_trick_index += 1

    new_trick
  end

  def bid_said_by_team
    BelotePlayers.player_team_symb(@mode.bid_said_by)
  end

  def opposing_team
    (BelotePlayers::TEAMS_SYMB - [bid_said_by_team]).first
    #BelotePlayers::TEAMS_SYMB.reject { |team| team == bid_said_by_team }.first
  end

  def inside?(points)
    points[bid_said_by_team] < points[opposing_team]
  end

  def hanging?(points)
    points[:north_south_team] == points[:east_west_team]
  end

  def tricks_of_team(team)
    raise ArgumentError "unknown team: #{team}" unless BelotePlayers::TEAMS_SYMB.include? team

    team_players = (team == :north_south_team) ? BelotePlayers::NORTH_SOUTH_TEAM : BelotePlayers::EAST_WEST_TEAM

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
  # returns match points
  def doubling_points(points, @mode)
    result = @mode.round(points[:north_south_team] + points[:east_west_team])
    result *= 2 if @mode.instance_of? DoubleMode
    result *= 4 if @mode.instance_of? RedoubleMode

    result
  end

  # REFACTOR
  def tricks_points(tricks)
    tricks.map(&:points)
      .reduce({:north_south_team => 0, :east_west_team => 0}) do |memo, points|
        memo.merge(points) { |key, oldval, newval| newval + oldval }    # NOTE: can use BeloteGame#sum_points
      end
  end

  # REVIEW: case valat
  # REVIEW: points rounding
  # REVIEW: hanging
  # REFACTOR: maybe, code repetition
  def points
    deal_points = tricks_points @tricks

    if not inside? deal_points
      deal_points[bid_said_by_team] += MatchPoints::VALAT_BONUS if valat? @tricks

      if not @mode.is_a? DoubleMode
        @mode.match_points deal_points
      else
        {bid_said_by_team => doubling_points(deal_points, @mode),
         opposing_team    => 0}
      end
    elsif inside? deal_points
      deal_points[opposing_team] += MatchPoints::VALAT_BONUS if valat? @tricks

      {bid_said_by_team => 0,
       opposing_team    => doubling_points(deal_points, @mode)}
    elsif hanging? deal_points
      if not @mode.is_a? DoubleMode
        @mode.match_points deal_points
      else
        doubled_points = doubling_points(deal_points, @mode)
        {bid_said_by_team => doubled_points / 2,
         opposing_team    => doubled_points / 2}
      end
    end
  end

  # Cards won by one team are added on top of the others to assemble new deck for next deal
  def assemble_deck
    cards = (north_south_tricks + east_west_tricks).map(&:cards)
    Deck.new cards
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
trick.player_on_turn_tell_announce(announce)
trick.player_on_turn_play_card(card)
# second third fourth

trick = deal.next_trick
# ...

p = deal.points


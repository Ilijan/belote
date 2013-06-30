# TODO: rename file to player.rb
require 'card'

class Player
  attr_reader :name
  attr_accessor :hand

  def initialize(name)
    @name = name
    @hand = Hand.new
  end
end

class BelotePlayers
  PLAYERS_ORDINANCE = [:north, :west, :south, :east]
  NORTH_SOUTH_TEAM = [:north, :south]
  EAST_WEST_TEAM = [:east, :west]
  TEAMS_SYM = [:north_south_team, :east_west_team]

  attr_reader :player_on_turn_position

  def self.check(player_position)
    unless PLAYERS_ORDINANCE.include? player_position
      raise ArgumentError, "invalid player position: #{player_position}"
    end
  end

  def self.check_team_sym(team)
    unless TEAMS_SYM.include? team
      raise ArgumentError, "invalid team: #{team}"
    end
  end

  def self.player_after(player_position)
    check player_position

    index = PLAYERS_ORDINANCE.find_index(player_position) + 1
    PLAYERS_ORDINANCE[index % PLAYERS_ORDINANCE.size]
  end

  def self.north_south_team?(player_position)
    check player_position

    NORTH_SOUTH_TEAM.include? player_position
  end

  def self.east_west_team?(player_position)
    check player_position

    EAST_WEST_TEAM.include? player_position
  end

  def self.player_team(player_position)
    check player_position

    north_south_team?(player_position) ? NORTH_SOUTH_TEAM : EAST_WEST_TEAM
  end

  # REVIEW: rename to player_team!
  #   naming convention: all function that return array end with !, others don't; no .._sym
  def self.player_team_sym(player_position)
    check player_position

    north_south_team?(player_position) ? :north_south_team : :east_west_team
  end

  def self.opposing_team(team_sym)
    check_team_sym team_sym

    (TEAMS_SYM - [team_sym]).first
  end

  def self.team_players(team_sym)
    check_team_sym team_sym

    (team_sym == :north_south_team) ? NORTH_SOUTH_TEAM : EAST_WEST_TEAM
  end

  # hash with Player, positon of first, cycles
  def initialize(players, first, max_cycles = 0)
    raise ArgumentError, "wrong players count" unless players.keys.size == 4
    @players = players

    self.class.check first
    @player_on_turn_position = first

    raise ArgumentError, "max cycles: #{max_cycles}" if max_cycles < 0
    @cycles = (max_cycles == 0) ? -1 : (max_cycles * PLAYERS_ORDINANCE.size - 1)
  end

  def player_on_position(player_position)
    self.class.check player_position

    @players[player_position]
  end

  # def to_a
    # @players.to_a
  # end

  def to_hash
    @players
  end

  def player_on_turn
    @players[@player_on_turn_position]
  end

  def next_player_on_turn
    raise "Cannot cycle more" if @cycles == 0   # REVIEW: raise StopIteration
    @cycles -= 1

    @player_on_turn_position = self.class.player_after @player_on_turn_position

    player_on_turn
  end
end

require 'card'
require 'announces'

class Player
  attr_reader :name
  attr_accessor :hand

  def initialize(name)
    @name = name
    @hand = Hand.new
  end
end

class BelotePlayers#Succession
  PLAYERS_ORDINANCE = [:north, :west, :south, :east]
  NORTH_SOUTH_TEAM = [:north, :south]
  EAST_WEST_TEAM = [:east, :west]
  TEAMS_SYMB = [:north_south_team, :east_west_team]

  attr_reader :player_on_turn_position

  def self.check(player_position)
    unless PLAYERS_ORDINANCE.include? player_position
      raise ArgumentError "wrong player position #{player_position}"
    end
  end

  def self.player_after(current_player_position)
    check current_player_position

    index = PLAYERS_ORDINANCE.find_index(current_player_position) + 1
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

  def self.player_team_symb(player_position)
    check player_position

    north_south_team?(player_position) ? :north_south_team : :east_west_team
  end
  
  def self.opposing_team(team_symb)
    [TEAMS_SYMB - team_symb].first
  end

  # hash with Player, positon of first, cycles
  def intialize(players, first, max_cycles=-1)
    raise ArgumentError "wrong players count" unless players.size != 4
    @players = players

    self.class.check first
    @player_on_turn_position = first
    @cycles = max_cycles * PLAYERS_ORDINANCE.size
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
    raise "Cannot cycle more" if cycles == 0
    cycles -= 1

    @player_on_turn_position = self.class.player_after @player_on_turn_position

    player_on_turn
  end
end

class BeloteTable
  attr_reader :players

  def initialize
    @players = []
  end

  def add_player
  end
end

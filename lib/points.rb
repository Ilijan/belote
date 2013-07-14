require 'belote_table'

class Points
  def self.sum(points1, points2)
    Points.new self.sum_hash(points1.to_hash, points2.to_hash)
  end

  def self.zeros
    Points.new north_south_team: 0, east_west_team: 0
  end

  def initialize(points) # REVIEW: taking mode as arg but this will mess with global match points score
    raise ArgumentError, "unknown teams" unless (BelotePlayers::TEAMS_SYM - points.keys).empty?
    raise ArgumentError, "negative points" unless points.values.all? { |v| v >= 0}
    
    @points = points
  end

  def to_hash
    @points.clone
  end

  def clone
    Points.new @points.clone  # NOTE: @points hash does not have references inside and should not
  end

  def hanging?
    @points[:north_south_team] == @points[:east_west_team]
  end
  
  def team_with_max_points
    return nil if hanging?
    @points.max { |a, b| a.last <=> b.last }.first
  end

  def inside?(bid_said_by_team)
    opposing_team = BelotePlayers.opposing_team bid_said_by_team

    @points[bid_said_by_team] < @points[opposing_team]
  end

  def add(points, team_receiving_points = nil)
    return if points.nil?   # REVIEW: should we?; why not;
                            #         this is optimization for BeloteGame#take_and_clear_hanging_points

    hash_points = points.to_hash

    if team_receiving_points
      opposing_team = BelotePlayers.opposing_team team_receiving_points
      hash_points[opposing_team] = 0
    end

    @points = self.class.sum_hash @points, hash_points
  end

  def add_points_to(team_receiving_points, value)
    points = Points.zeros
    points[team_receiving_points] = value
    add points, team_receiving_points
  end

  def all
    @points.values.reduce(:+)
  end

  def north_south
    @points[:north_south_team]
  end

  # def north_south=(value)
    # @points[:north_south_team] = value
  # end

  def east_west
    @points[:east_west_team]
  end

  # def east_west=(value)
    # @points[:east_west_team] = value
  # end

  # REFACTOR: repeating functionality as in #[], solve alias_method ?
  def team_points(team)
    @points[team]
  end

  def opposing_team_points(team)
    opposing_team = BelotePlayers.opposing_team team

    @points[opposing_team]
  end
  
  def +(other)
    Points.sum self, other
  end

  # REFACTOR: repeating functionality as in #team_points, solve alias_method ?
  def [](team)
    @points[team]
  end

  def []=(team, value)
    @points[team] = value
  end

  private
  def self.sum_hash(points1, points2)
    points1.merge(points2) { |key, oldval, newval| newval + oldval }
  end
end

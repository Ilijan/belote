describe 'Points' do
  it 'initialize properly' do
    lambda do
      Points.new north_south_team: 0, east_west_team: 0
      Points.new north_south_team: 123, east_west_team: 34
    end.should_not raise_error ArgumentError

    lambda do
      Points.new north_south_team: 0
      Points.new north_south_team: 0, east_west_team: -2
      Points.new east_west_team: 123
      Points.new north_south_team: -5, east_west_team: -2
      Points.new north_south_team: 423432, east_west_team: -21431
      Points.new north_south_team: -423432, east_west_team: 21431
    end.should raise_error ArgumentError
  end

  it 'converts to hash' do
    arg = {north_south_team: 45, east_west_team: 3}
    Points.new(arg).to_hash.should eq arg
  end
  
  # it 'sums hash representing points (private)' do    
  # end

  it 'sums points' do
    [
      [{north_south_team: 11, east_west_team: 12}, {north_south_team: 6, east_west_team: 12}],
      [{north_south_team: 0, east_west_team: 8}, {north_south_team: 5, east_west_team: 12}],
    ].each do |first, second|
      # REVIEW: merge
      result = {:north_south_team => (first[:north_south_team] + second[:north_south_team]),
                :east_west_team => (first[:east_west_team] + second[:east_west_team])}

      # REVIEW: operator ==
      sum = Points.sum(Points.new(first), Points.new(second))
      sum.to_hash.should eq result
    end
  end

  it 'creates 0 points' do
    Points.zeros.to_hash.should eq({north_south_team: 0, east_west_team: 0})
  end

  it 'tells if points are equal a.k.a. hanging' do
    [
      [{north_south_team: 0, east_west_team: 0}, true],
      [{north_south_team: 151, east_west_team: 151}, true],

      [{north_south_team: 123, east_west_team: 65}, false],
      [{north_south_team: 0, east_west_team: 65}, false],
    ].each do |arg, result|
      Points.new(arg).hanging?.should eq result
    end
  end

  it 'tells which team has max points' do
    [
      [{north_south_team: 123, east_west_team: 65}, :north_south_team],
      [{north_south_team: 0, east_west_team: 65}, :east_west_team],

      [{north_south_team: 0, east_west_team: 0}, nil],
      [{north_south_team: 151, east_west_team: 151}, nil],
    ].each do |arg, result|
      Points.new(arg).team_with_max_points.should eq result
    end
  end

  it 'tells which team is inside' do
    [
      [{north_south_team: 151, east_west_team: 12}, :east_west_team, true],
      [{north_south_team: 5, east_west_team: 151}, :north_south_team, true],
      [{north_south_team: 0, east_west_team: 160}, :north_south_team, true],

      [{north_south_team: 123, east_west_team: 65}, :north_south_team, false],
      [{north_south_team: 0, east_west_team: 65}, :east_west_team, false],
      [{north_south_team: 0, east_west_team: 0}, :north_south_team,false],
      [{north_south_team: 151, east_west_team: 151}, :east_west_team, false],
    ].each do |arg, bid_said_by, result|
      Points.new(arg).inside?(bid_said_by).should eq result
    end
  end

  describe 'adds other points to itself' do
    it 'for both teams' do
      [
        [{north_south_team: 11, east_west_team: 12}, {north_south_team: 6, east_west_team: 12}],
        [{north_south_team: 0, east_west_team: 8}, {north_south_team: 5, east_west_team: 12}],
      ].each do |init, other|
        # REVIEW: merge
        result = {:north_south_team => (init[:north_south_team] + other[:north_south_team]),
                  :east_west_team => (init[:east_west_team] + other[:east_west_team])}

        Points.new(init).add(Points.new(other)).should eq result
      end
    end

    it 'for both teams using +/+' do
      [
        [{north_south_team: 11, east_west_team: 12}, {north_south_team: 6, east_west_team: 12}],
        [{north_south_team: 0, east_west_team: 8}, {north_south_team: 5, east_west_team: 12}],
      ].each do |init, other|
        # REVIEW: merge
        result = {:north_south_team => (init[:north_south_team] + other[:north_south_team]),
                  :east_west_team => (init[:east_west_team] + other[:east_west_team])}

        # REVIEW: operator ==
        (Points.new(init) + Points.new(other)).to_hash.should eq result
      end
    end

    it 'for specified team only' do
      [
        [{north_south_team: 0, east_west_team: 0}, {north_south_team: 0, east_west_team: 0}, :north_south_team],
        [{north_south_team: 0, east_west_team: 0}, {north_south_team: 0, east_west_team: 0}, :east_west_team],
        [{north_south_team: 11, east_west_team: 12}, {north_south_team: 6, east_west_team: 12}, :north_south_team],
        [{north_south_team: 0, east_west_team: 8}, {north_south_team: 5, east_west_team: 12}, :north_south_team],
        [{north_south_team: 5, east_west_team: 8}, {north_south_team: 5, east_west_team: 12}, :east_west_team],
      ].each do |init, other, team_receiving_points|
        # REVIEW: merge
        result = init.merge(other) { |key, old, new| (key == team_receiving_points) ? old + new : old }

        Points.new(init).add(Points.new(other), team_receiving_points).should eq result
      end
    end
  end

  it 'adds points value to one team only' do
    [
      [{north_south_team: 0, east_west_team: 0}, :north_south_team, 0],
      [{north_south_team: 0, east_west_team: 0}, :east_west_team, 4],
      [{north_south_team: 11, east_west_team: 12}, :north_south_team, 2],
      [{north_south_team: 0, east_west_team: 8}, :north_south_team, 5],
      [{north_south_team: 5, east_west_team: 8}, :east_west_team, 7],
    ].each do |init, team_receiving_points, points|
      # REVIEW: merge
      result = init.merge({team_receiving_points => (init[team_receiving_points] + points)})

      Points.new(init).add_points_to(team_receiving_points, points).should eq result
    end
  end

  it 'sums both team points' do
    [
      {north_south_team: 0, east_west_team: 0},
      {north_south_team: 4, east_west_team: 4},
      {north_south_team: 11, east_west_team: 12},
      {north_south_team: 123, east_west_team: 8},
      {north_south_team: 5, east_west_team: 8},
    ].each do |points|
      result = points[:north_south_team] + points[:east_west_team]

      Points.new(points).all.should eq result
    end
  end

  it 'tells north team points' do
    [
      {north_south_team: 5, east_west_team: 54},
      {north_south_team: 6, east_west_team: 4},
      {north_south_team: 11, east_west_team: 12},
      {north_south_team: 123, east_west_team: 8},
      {north_south_team: 46, east_west_team: 8},
    ].each do |arg|
      Points.new(arg).north_south.should eq arg[:north_south_team]
    end
  end

  it 'tells north team points' do
    [
      {north_south_team: 5, east_west_team: 54},
      {north_south_team: 6, east_west_team: 4},
      {north_south_team: 11, east_west_team: 12},
      {north_south_team: 123, east_west_team: 8},
      {north_south_team: 46, east_west_team: 8},
    ].each do |arg|
      Points.new(arg).east_west.should eq arg[:east_west_team]
    end
  end

  it 'tells points for given team' do
    [
      [{north_south_team: 5, east_west_team: 54}, :east_west_team],
      [{north_south_team: 6, east_west_team: 4}, :north_south_team],
      [{north_south_team: 11, east_west_team: 12}, :east_west_team],
      [{north_south_team: 123, east_west_team: 8}, :north_south_team],
      [{north_south_team: 46, east_west_team: 8}, :east_west_team],
    ].each do |arg, team|
      Points.new(arg).team_points(team).should eq arg[team]
    end
  end

  it 'tells points for the opposing of given team' do
    [
      [{north_south_team: 5, east_west_team: 54}, :east_west_team],
      [{north_south_team: 6, east_west_team: 4}, :north_south_team],
      [{north_south_team: 11, east_west_team: 12}, :east_west_team],
      [{north_south_team: 123, east_west_team: 8}, :north_south_team],
      [{north_south_team: 46, east_west_team: 8}, :east_west_team],
    ].each do |arg, team|
      opposing_team = (team == :north_south_team) ? :east_west_team : :north_south_team
      Points.new(arg).opposing_team_points(team).should eq arg[opposing_team]
    end
  end

  it 'tells points for given team using []' do
    [
      [{north_south_team: 5, east_west_team: 54}, :east_west_team],
      [{north_south_team: 6, east_west_team: 4}, :north_south_team],
      [{north_south_team: 11, east_west_team: 12}, :east_west_team],
      [{north_south_team: 123, east_west_team: 8}, :north_south_team],
      [{north_south_team: 46, east_west_team: 8}, :east_west_team],
    ].each do |arg, team|
      Points.new(arg)[team].should eq arg[team]
    end
  end
  
  it 'assign points for given team using []=' do
    [
      [{north_south_team: 5, east_west_team: 54}, :east_west_team, 6],
      [{north_south_team: 6, east_west_team: 4}, :north_south_team, 43],
      [{north_south_team: 11, east_west_team: 12}, :east_west_team, 1],
      [{north_south_team: 123, east_west_team: 8}, :north_south_team , 0],
      [{north_south_team: 46, east_west_team: 8}, :east_west_team, 0],
    ].each do |arg, team_receiving_points, value|
      result = arg.merge({team_receiving_points => value})

      points = Points.new arg
      points[team_receiving_points] = value
      points.to_hash.should eq result
    end
  end
end
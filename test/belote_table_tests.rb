describe "Player" do
  let(:player) { Player.new 'Some name' }

  it 'initialize properly' do
    lambda { Player.new 'KolioMasta' }.should_not raise_error StandardError

    lambda { Player.new }.should raise_error ArgumentError
  end

  it 'have hand of cards' do
    player.hand.cards.size.should eq 0

    player.hand = Hand.new [Card.new(:spades, :ace)]
    player.hand.cards.should eq [Card.new(:spades, :ace)]
  end
end

describe "BelotePlayers" do
  let(:players_hash) do
    {:north => Player.new('Player1'),
     :south => Player.new('Player2'),
     :east  => Player.new('Player3'),
     :west  => Player.new('Player4')}
  end

  let(:belote_players) { BelotePlayers.new players_hash, :north }

  it 'validates player position' do
    [:dsafs, :fdgdg, :norths, :eastt]
    .each do |player|
      lambda { BelotePlayers.check player }.should raise_error ArgumentError
    end

    [:west, :south, :north, :east]
    .each do |player|
      lambda { BelotePlayers.check player }.should_not raise_error ArgumentError
    end
  end

  it 'validates team' do
    [:dsafs, :east_north_team, :north_west_team, :all_teams]
    .each do |team|
      lambda { BelotePlayers.check_team_sym team }.should raise_error ArgumentError
    end

    [:north_south_team, :east_west_team]
    .each do |team|
      lambda { BelotePlayers.check_team_sym team }.should_not raise_error ArgumentError
    end
  end

  it 'can tell which player is after another' do
    [[:north, :west],
     [:west, :south],
     [:south, :east],
     [:east, :north],
    ].each do |player, next_player|
      BelotePlayers.player_after(player).should eq next_player
    end
  end

  it 'can tell if player is in north-west team or in east-west team' do
    BelotePlayers.north_south_team?(:north).should be_true
    BelotePlayers.north_south_team?(:south).should be_true

    BelotePlayers.east_west_team?(:east).should be_true
    BelotePlayers.east_west_team?(:west).should be_true

    # false cases
    BelotePlayers.north_south_team?(:east).should be_false
    BelotePlayers.north_south_team?(:west).should be_false

    BelotePlayers.east_west_team?(:north).should be_false
    BelotePlayers.east_west_team?(:south).should be_false
  end

  it 'can tell who are the players in team with given player' do
    BelotePlayers.player_team(:north).should include :north, :south
    BelotePlayers.player_team(:south).should include :north, :south

    BelotePlayers.player_team(:east).should include :east, :west
    BelotePlayers.player_team(:west).should include :east, :west

    # false cases
    BelotePlayers.player_team(:north).should_not include :east, :west
    BelotePlayers.player_team(:south).should_not include :east, :west

    BelotePlayers.player_team(:east).should_not include :north, :south
    BelotePlayers.player_team(:west).should_not include :north, :south
  end

  it 'can tell player\'s team' do
    BelotePlayers.player_team_sym(:north).should eq :north_south_team
    BelotePlayers.player_team_sym(:south).should eq :north_south_team

    BelotePlayers.player_team_sym(:east).should eq :east_west_team
    BelotePlayers.player_team_sym(:west).should eq :east_west_team
  end

  it 'can tell which is the opposing team of given team' do
    BelotePlayers.opposing_team(:north_south_team).should eq :east_west_team
    BelotePlayers.opposing_team(:east_west_team).should eq :north_south_team
  end

  it 'can tell players in team' do
    BelotePlayers.team_players(:north_south_team).should include :north, :south
    BelotePlayers.team_players(:east_west_team).should include :east, :west

    # false cases
    BelotePlayers.team_players(:north_south_team).should_not include :east, :west
    BelotePlayers.team_players(:east_west_team).should_not include :north, :south
  end

  it 'initialize properly' do
    lambda do
      belote_players

      BelotePlayers.new(players_hash, :north)
      BelotePlayers.new(players_hash, :west, 1)
      BelotePlayers.new(players_hash, :west, 100)
      BelotePlayers.new(players_hash, :west, 0)
    end.should_not raise_error ArgumentError

    lambda { BelotePlayers.new({north: nil, south: nil}, :west) }.should raise_error ArgumentError

    lambda { BelotePlayers.new(players_hash, :west1) }.should raise_error ArgumentError

    lambda { BelotePlayers.new players_hash, :west, -1 }.should raise_error ArgumentError
  end

  it 'knows player on position' do
    [:north, :south, :east, :west]
    .each do |player|
      belote_players.player_on_position(player).should eq players_hash[player]
    end

    lambda do
      belote_players.player_on_position(:asd)
      belote_players.player_on_position(:a241)
    end.should raise_error ArgumentError
  end

  it 'converts to hash' do
    belote_players.to_hash.should eq players_hash
  end

  it 'knows player on turn and can move to next one' do
    [:north, :west, :south, :east]
    .cycle(23) do |player|
      belote_players.player_on_turn.should eq players_hash[player]
      belote_players.next_player_on_turn.should eq players_hash[BelotePlayers.player_after(player)]
    end

    players = BelotePlayers.new players_hash, :east, 1
    players.player_on_turn.should eq players_hash[:east]

    players.next_player_on_turn.should eq players_hash[:north]
    players.player_on_turn.should eq players_hash[:north]

    players.next_player_on_turn.should eq players_hash[:west]
    players.player_on_turn.should eq players_hash[:west]

    players.next_player_on_turn.should eq players_hash[:south]
    players.player_on_turn.should eq players_hash[:south]

    lambda { players.next_player_on_turn }.should raise_error RuntimeError
  end
end

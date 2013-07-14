require_relative 'short_defines'

describe 'Trick' do
  include_context "Tests Helper"

  let(:players_hands) do
    {:north => hand(to_cards(%w[sa sq sk s10 s9])),
     :south => hand(to_cards(%w[ha hq hk h10 h9])),
     :east  => hand(to_cards(%w[da dq dk d10 d9])),
     :west  => hand(to_cards(%w[ca cq ck c10 c9]))}
  end

  let(:players_hash) do
    result = {:north => Player.new('Player1'),
              :south => Player.new('Player2'),
              :east  => Player.new('Player3'),
              :west  => Player.new('Player4')}
    result.merge(players_hands) { |key, player, hand| player.hand = hand; player }
  end

  let(:mode) { AllTrumpsMode.new }

  let(:trick) { Trick.new players_hash, :north, mode }

  it 'initialize properly' do
    lambda do
      Trick.new players_hash, :north, mode
      Trick.new players_hash, :north, mode, true
      Trick.new players_hash, :north, mode, false
    end.should_not raise_error ArgumentError

    lambda do
      trick = Trick.new players_hash, :north, mode
      trick.cards.should eq({})
      trick.first_player.should eq :north
      trick.last_trick?.should  be_false
    end.should_not raise_error ArgumentError

    # lambda do
    trick.cards.should eq({})
    trick.first_player.should eq :north
    trick.last_trick?.should be_false
    # end
  end

  it 'tells if player have belote' do
    # players_hash[:north].hand.add_cards [Card.new(:spades, :king), Card.new(:spades, :queen)]
    # trick = Trick.new players_hash, :north, AllTrumpsMode.new
    trick.have_belote?(:north, Card.new(:spades, :king)).should be_true

    # trick = Trick.new players_hash, :north, NoTrumpsMode.new
    # trick.have_belote?(:north, Card.new(:spades, :king)).should be_false
  end

  describe 'plays card' do
    it 'without announcing belote' do
      trick.play_card(:north, card('sk'))
      players_hash[:north].hand.cards.should_not include card('sk')

      trick.play_card(:north, card('s10'))
      players_hash[:north].hand.cards.should_not include card('s10')
    end

    it 'with announcing belote' do
      trick.play_card(:north, Card.new(:spades, :king), true)
      players_hash[:north].hand.cards.should_not include Card.new(:spades, :king)
    end
  end

  it 'tells winner' do
    trick.play_card(:north, card('sk'))
    trick.play_card(:south, card('hk'))
    trick.play_card(:east, card('dk'))
    trick.play_card(:west, card('ck'))

    trick.winner.should eq :north
  end

  it 'calculates points of the trick' do
    trick.play_card(:north, card('sk'))
    trick.play_card(:south, card('hk'))
    trick.play_card(:east, card('dk'))
    trick.play_card(:west, card('ck'))

    trick.trick_card_points.should eq 16
  end

  it 'tells announces points(only belotes)' do
    team1_announces = [[:belote,], [:therta,], [:belote,]]
    team2_announces = [[:quinta,], [:quarta,], [:carre,]]
    points = trick.announces_points team1_announces, team2_announces
    points.should eq [40, 0]
  end

  it 'tells points(+ belotes announces)' do
    trick.play_card(:north, card('sk'))
    trick.play_card(:south, card('hk'))
    trick.play_card(:east, card('dk'), true)
    trick.play_card(:west, card('ck'))

    trick.points.to_hash.should eq({north_south_team: 16, east_west_team: 20})
  end
end

describe 'FirstTrick' do
  include_context "Tests Helper"

  let(:players_hands) do
    {:north => hand(to_cards(%w[sa sk sq s8 s9])),
     :south => hand(to_cards(%w[ha s10 h10 d10 c10])),
     :east  => hand(to_cards(%w[da dk dq dj d10])),
     :west  => hand(to_cards(%w[ca cq ck c10 c9]))}
  end

  let(:players_hash) do
    result = {:north => Player.new('Player1'),
              :south => Player.new('Player2'),
              :east  => Player.new('Player3'),
              :west  => Player.new('Player4')}
    result.merge(players_hands) { |key, player, hand| player.hand = hand; player }
  end

  let(:mode) { AllTrumpsMode.new }

  let(:first_trick) { FirstTrick.new players_hash, :north, mode }

  it 'tells players possible announces' do
    FirstTrick.new(players_hash, :north, NoTrumpsMode.new).announces(:north).should eq []

    announces = first_trick.announces(:north)
    announces.map(&:first).should eq [:belote, :therta]
  end

  it 'declares announces' do
    first_trick.declare_announce :north, [:therta]
    first_trick.declare_announce :north, [:belote]
    first_trick.declare_announce :south, [:belote]
  end

  it 'calculates announces points' do
    team1_announces = [[:belote,], [:therta, [:ace,]], [:belote,]]
    team2_announces = [[:quinta, [:ace,]], [:quarta, [:ace,]], [:carre, :r10], [:therta, [:king,]]]
    points = first_trick.announces_points team1_announces, team2_announces
    points.should eq [60, 250]
  end
end
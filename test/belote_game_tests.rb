describe "BidPhase" do
  let(:players_hash) { {:north => Player.new('Player1'),
                        :south => Player.new('Player2'),
                        :east  => Player.new('Player3'),
                        :west  => Player.new('Player4')} }

  let(:bid_phase) { BidPhase.new players_hash, :north }

  it 'initialize properly' do
    bid_phase = BidPhase.new players_hash, :north

    bid_phase.won_bid.should be_nil
    bid_phase.bid_said_by.should be_nil
    bid_phase.double?.should be_false
    bid_phase.redouble?.should be_false

    bid_phase.player_on_turn.should eq players_hash[:north]
    bid_phase.player_on_turn_position.should eq :north
    bid_phase.next_player_on_turn.should eq players_hash[:west]
    bid_phase.next_player_on_turn.should eq players_hash[:south]

    lambda { BidPhase.new players_hash, :north1 }.should raise_error ArgumentError

    lambda do
      players_hash.delete :south
      BidPhase.new players_hash, :north1
    end.should raise_error ArgumentError
  end

  # NOTE: Does not check if bid is lower than current won_bid and who bids what
  describe 'can bid and' do
    it 'validates bid' do
      bid_phase.set_bid :north, :pass
      bid_phase.set_bid :north, :clubs
      bid_phase.set_bid :north, :hearts
      bid_phase.set_bid :north, :diamonds
      bid_phase.set_bid :north, :spades
      bid_phase.set_bid :north, :notrumps
      bid_phase.set_bid :north, :alltrumps
      bid_phase.set_bid :north, :double
      bid_phase.set_bid :north, :redouble

      # false cases
      lambda { bid_phase.set_bid :north, :club }.should raise_error ArgumentError
      lambda { bid_phase.set_bid :north, :no_trump }.should raise_error ArgumentError
      lambda { bid_phase.set_bid :north, :asd }.should raise_error ArgumentError
    end

    it 'say pass' do
      bid_phase.set_bid :north, :pass
      bid_phase.won_bid.should be_nil

      bid_phase.set_bid :south, :pass
      bid_phase.won_bid.should be_nil

      bid_phase.set_bid :east, :pass
      bid_phase.won_bid.should be_nil

      bid_phase.set_bid :west, :pass
      bid_phase.won_bid.should be_nil
    end

    it 'remembers bit' do
      bid_phase.set_bid :north, :clubs
      bid_phase.won_bid.should eq :clubs

      bid_phase.set_bid :north, :diamonds
      bid_phase.won_bid.should eq :diamonds

      bid_phase.set_bid :north, :hearts
      bid_phase.won_bid.should eq :hearts

      bid_phase.set_bid :north, :spades
      bid_phase.won_bid.should eq :spades

      bid_phase.set_bid :north, :notrumps
      bid_phase.won_bid.should eq :notrumps

      bid_phase.set_bid :north, :alltrumps
      bid_phase.won_bid.should eq :alltrumps
    end

    it 'does doubling right' do
      bid_phase.set_bid :north, :hearts
      bid_phase.set_bid :east, :double

      bid_phase.won_bid.should eq :hearts
      bid_phase.double?.should be_true

      bid_phase.set_bid :north, :redouble
      bid_phase.redouble?.should be_true
    end

    it 'tells what is the doubling' do
      bid_phase.set_bid :north, :spades
      bid_phase.doubling.should be_nil

      bid_phase.set_bid :north, :double
      bid_phase.doubling.should eq :double
      bid_phase.set_bid :north, :redouble
      bid_phase.doubling.should eq :redouble
    end

    it 'raises error if trying to double no bid' do
      lambda { bid_phase.set_bid :south, :double }.should raise_error ArgumentError
      lambda { bid_phase.set_bid :south, :redouble }.should raise_error ArgumentError
    end

    it 'pass does not change bid' do
      bid_phase.set_bid :north, :clubs

      bid_phase.set_bid :south, :pass
      bid_phase.won_bid.should eq :clubs

      bid_phase.set_bid :east, :double
      bid_phase.won_bid.should eq :clubs

      bid_phase.set_bid :south, :redouble
      bid_phase.won_bid.should eq :clubs
    end
  end

  describe 'can tell what are possible bids in any moment of the phase;' do
    it 'all bids' do
      [:pass, :alltrumps, :notrumps, :spades, :hearts, :diamonds, :clubs]
      .should eq bid_phase.possible_bids(:north)
    end

    it 'bids above diamonds' do
      bid_phase.set_bid :north, :diamonds

      [:pass, :redouble, :double, :alltrumps, :notrumps, :spades, :hearts]
      .should eq bid_phase.possible_bids(:west)

      [:pass, :alltrumps, :notrumps, :spades, :hearts]
      .should eq bid_phase.possible_bids(:south)
    end

    it 'doubling diamonds' do
      bid_phase.set_bid :north, :diamonds

      [:pass, :redouble, :double, :alltrumps, :notrumps, :spades, :hearts]
      .should eq bid_phase.possible_bids(:east)
      bid_phase.set_bid :east, :double

      [:pass, :alltrumps, :notrumps, :spades, :hearts]
      .should eq bid_phase.possible_bids(:west)

      [:pass, :redouble, :alltrumps, :notrumps, :spades, :hearts]
      .should eq bid_phase.possible_bids(:south)
    end

    it 'redouble alltrumps' do
      bid_phase.set_bid :north, :alltrumps
      bid_phase.set_bid :west, :double

      [:pass, :redouble]
      .should eq bid_phase.possible_bids(:south)
      bid_phase.set_bid :south, :redouble

      [:pass]
      .should eq bid_phase.possible_bids(:east)

      [:pass]
      .should eq bid_phase.possible_bids(:north)
    end
  end

  it 'end of bidding' do
    bid_phase.set_bid :north, :pass
    bid_phase.set_bid :west, :pass
    bid_phase.set_bid :south, :pass
    bid_phase.set_bid :east, :pass

    bid_phase.end_of_bidding?.should be_true
  end

  it 'clear doubling' do
    bid_phase.set_bid :north, :spades

    bid_phase.set_bid :west, :double
    bid_phase.clear_doubling
    bid_phase.double?.should be_false

    bid_phase.set_bid :west, :redouble
    bid_phase.clear_doubling
    bid_phase.redouble?.should be_false
  end

  # REFACTOR
  it 'example bid' do
    # north on turn; bid diamonds
    bid_phase.player_on_turn_position.should eq :north
    bid_phase.player_on_turn.should eq players_hash[:north]

    [:pass, :alltrumps, :notrumps, :spades, :hearts, :diamonds, :clubs]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :diamonds

    # west on turn; bid spades
    bid_phase.next_player_on_turn.should eq players_hash[:west]

    [:pass, :redouble, :double, :alltrumps, :notrumps, :spades, :hearts]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :spades

    # south on turn; pass
    bid_phase.next_player_on_turn.should eq players_hash[:south]

    [:pass, :redouble, :double, :alltrumps, :notrumps]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :pass

    # east on turn; bid alltrump
    bid_phase.next_player_on_turn.should eq players_hash[:east]

    [:pass, :alltrumps, :notrumps]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :alltrumps

    # north on turn; bid double
    bid_phase.next_player_on_turn.should eq players_hash[:north]

    [:pass, :redouble, :double]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :double

    # west on turn; pass
    bid_phase.next_player_on_turn.should eq players_hash[:west]

    [:pass, :redouble]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :pass

    # south on turnl; pass
    bid_phase.next_player_on_turn.should eq players_hash[:south]

    [:pass]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :pass

    # east on turn; bid redouble
    bid_phase.next_player_on_turn.should eq players_hash[:east]

    [:pass, :redouble]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :redouble

    # north on turn; pass
    bid_phase.next_player_on_turn.should eq players_hash[:north]

    [:pass]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :pass

    # west on turn; pass
    bid_phase.next_player_on_turn.should eq players_hash[:west]

    [:pass]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :pass

    # south on turn; pass
    bid_phase.next_player_on_turn.should eq players_hash[:south]

    [:pass]
    .should eq bid_phase.player_on_turn_possible_bids

    bid_phase.player_on_turn_set_bid :pass

    lambda { bid_phase.next_player_on_turn }.should raise_error StopIteration
  end
end

# DealGame
describe "DealGame" do
  let(:players_hash) { {:north => Player.new('Player1'),
                        :south => Player.new('Player2'),
                        :east  => Player.new('Player3'),
                        :west  => Player.new('Player4')} }

  let(:deck) { BeloteDeck.new } # same deck always
  let(:deal_game) { DealGame.new players_hash, :north, BeloteDeck.new }
  let(:player) { Player.new "dummy" }

  it 'initialize properly' do
    deal_game = DealGame.new players_hash, :north, BeloteDeck.new

    deal_game.first_player.should eq :north
    deal_game.mode.should be_nil

    lambda { DealGame.new players_hash, :north1, BeloteDeck.new }.should raise_error ArgumentError

    lambda do
      players_hash.delete :south
      DealGame.new players_hash, :north, BeloteDeck.new
    end.should raise_error ArgumentError
  end

  it 'deal number of cards to player' do
    deal_game.deal_cards player, 3
    player.hand.cards.size.should eq 3
    player.hand.cards.should eq deck.take_top_cards 3

    player2 = Player.new("name")
    deal_game.deal_cards player2, 6
    player2.hand.cards.size.should eq 6
    player2.hand.cards.should eq deck.take_top_cards 6
  end

  it 'deal cards to all' do
    deal_game.deal_cards_to_all 3

    players_hash[:north].hand.cards.size.should eq 3
    players_hash[:north].hand.cards.should eq deck.take_top_cards 3

    players_hash[:west].hand.cards.size.should eq 3
    players_hash[:west].hand.cards.should eq deck.take_top_cards 3

    players_hash[:south].hand.cards.size.should eq 3
    players_hash[:south].hand.cards.should eq deck.take_top_cards 3

    players_hash[:east].hand.cards.size.should eq 3
    players_hash[:east].hand.cards.should eq deck.take_top_cards 3
  end

  it 'deal first five cards; first deal by 3 then by 2 cards each' do
    deal_game.deal_first_five_cards

    players_hash[:north].hand.cards.size.should eq 5
    players_hash[:west].hand.cards.size.should eq 5
    players_hash[:south].hand.cards.size.should eq 5
    players_hash[:east].hand.cards.size.should eq 5

    players_hash[:north].hand.cards.should include *deck.take_top_cards(3)
    players_hash[:west].hand.cards.should include *deck.take_top_cards(3)
    players_hash[:south].hand.cards.should include *deck.take_top_cards(3)
    players_hash[:east].hand.cards.should include *deck.take_top_cards(3)

    players_hash[:north].hand.cards.should include *deck.take_top_cards(2)
    players_hash[:west].hand.cards.should include *deck.take_top_cards(2)
    players_hash[:south].hand.cards.should include *deck.take_top_cards(2)
    players_hash[:east].hand.cards.should include *deck.take_top_cards(2)
  end

  it 'sets mode' do
    deal_game.set_mode :clubs
    deal_game.mode.should be_an_instance_of ClubsMode

    deal_game.set_mode :diamonds
    deal_game.mode.should be_an_instance_of DiamondsMode

    deal_game.set_mode :hearts
    deal_game.mode.should be_an_instance_of HeartsMode

    deal_game.set_mode :spades
    deal_game.mode.should be_an_instance_of SpadesMode

    deal_game.set_mode :notrumps
    deal_game.mode.should be_an_instance_of NoTrumpsMode

    deal_game.set_mode :alltrumps
    deal_game.mode.should be_an_instance_of AllTrumpsMode

    deal_game.set_mode :spades, :double
    deal_game.mode.should be_an_instance_of DoubleMode

    deal_game.set_mode :spades, :redouble
    deal_game.mode.should be_an_instance_of RedoubleMode

    lambda { deal_game.set_mode :pass }.should raise_error ArgumentError
    lambda { deal_game.set_mode :double }.should raise_error ArgumentError
    lambda { deal_game.set_mode :redouble }.should raise_error ArgumentError
  end
end
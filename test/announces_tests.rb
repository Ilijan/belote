describe 'Announces' do
  let(:announce) do
    class Test
      include Announces
    end
    Test.new
  end
  
  def card(short)
    Card.make_card_short(short)
  end

  def hand(*cards)
    Hand.new *cards;
  end

  def cards_arr(*strs)
    strs.map { |short| send(:card, short) }
  end
  
  def test_function(func, data)
    data.each do |*args, result|
      func.call(*args).should eq result
    end
  end
  
  it 'finds sequences of same suit' do
    hands = [
      [%w[c8 s8 c10 cj ha c7 c9 sj], %w[c8 c10 cj c7 c9]],
      [%w[hj da c8 sk sq s10 sj cj], %w[sk sq s10 sj]],
      [%w[h10 hj d9 hq d10 h9 c7 h8], %w[h10 hj hq h9 h8]],
      [%w[h10 dj d9 hq d10 h9 s7 d8], %w[dj d9 d10]],
      [%w[h10 dj d9 hq d10 h9 s7 d8], %w[dj d9 d10 d8]],
    ]
    
    func = lambda { |a, b| announce.sequence(a, b) }
    data = hands.map { |test_case| [hand(*cards_arr(*test_case[0])), test_case[1].size, cards_arr(*test_case[1])] }
    test_functionfunc, data
    
    # hands.each do |some_hand, result|
      # found_sequence = announce.sequence(hand(*cards_arr(*some_hand)), result.size)
      # found_sequence.should eq cards_arr *result
    # end
    
    no_announces = [
      [%w[h10 sj d9 hq d10 h9 d7 dk], []],
      [%w[s9 h8 d10 hq ca c7 d8 s10], []],
    ]
    
    (3..5).each do |length|
      data = no_announces.map { |test_case| [hand(*cards_arr(*test_case[0])), length, cards_arr(*test_case[1])] }
      test_function func, data
    end
  end
  
  it 'finds all sequences of given length and same suit' do
    hands = [
      [%w[h10 hj d9 hq d10 h9 c7 h8], 5, [%w[h10 hj hq h9 h8]]],
      [%w[sa sk sq sj da dk dq dj], 4, [%w[sa sk sq sj], %w[da dk dq dj]]],
      [%w[da dk dq d10 d9 d8 ha hk hq], 3, [%w[ha hk hq], %w[da dk dq], %w[d10 d9 d8]]],
    ]
    
    func = lambda { |a,b| announce.find_all_sequences(a, b) }
    data = hands.map do |test_case|
      [hand(*cards_arr(*test_case[0])), test_case[1], test_case[2].map { |result_part| cards_arr(*result_part) }]
    end
    test_function func, data
  end

  it 'finds quintas' do
    quintas = [
      [%w[c8 s8 c10 cj ha c7 c9 sj], %w[c8 c10 cj c7 c9]],
      [%w[hj sa c8 sk sq s10 sj cj], %w[sa sk sq s10 sj]],
      [%w[h10 hj d9 hq d10 h9 c7 h8], %w[h10 hj hq h9 h8]],
      [%w[h10 dj d9 hq d10 h9 d7 d8], %w[dj d9 d10 d7 d8]],
    ]
    
    func = lambda { |a| announce.find_quinta(a) }
    data = quintas.map do |test_case|
      [hand(*cards_arr(*test_case[0])), [:quinta, cards_arr(*test_case[1])] ]
    end
    test_function func, data
    
    
    no_announces = [
      %w[h10 hj d9 hq d10 h9 d7 d8],
      %w[s9 h8 d10 hq ca c7 d8 s10],
    ]
      
    data = no_announces.map { |some_hand| [hand(*cards_arr(*some_hand)), []] }
    test_function func, data
  end
  
  it 'finds quartas' do
    # quartas = [
      # [%w[c8 s8 c10 dj ha c7 c9 sj], [:quarta, cards_arr(*%w[c8 c10 c7 c9])]],
      # [%w[hj sa c8 sk sq sj dj cj], [:quarta, cards_arr(*%w[sa sk sq sj])]],
      # [%w[h10 hj d9 hq d10 h9 c7 s8], [:quarta, cards_arr(*%w[h10 hj hq h9])]],
      # [%w[h10 dj d9 hq d10 h9 s7 d8], [:quarta, cards_arr(*%w[dj d9 d10 d8])]],
      # [%w[sa sk sq sj da dk dq dj], [:quarta, cards_arr(*%w[sa sk sq sj]), cards_arr(*%w[da dk dq dj])]],
    # ]
    quartas = [
      [%w[c8 s8 c10 dj ha c7 c9 sj], [%w[c8 c10 c7 c9]]],
      [%w[hj sa c8 sk sq sj dj cj], [%w[sa sk sq sj]]],
      [%w[h10 hj d9 hq d10 h9 c7 s8], [%w[h10 hj hq h9]]],
      [%w[h10 dj d9 hq d10 h9 s7 d8], [%w[dj d9 d10 d8]]],
      [%w[sa sk sq sj da dk dq dj], [%w[sa sk sq sj],%w[da dk dq dj]]],
    ]
    
    func = lambda { |a, b| announce.find_quarta(a, b) }
    data = quartas.map do |test_case|
      [hand(*cards_arr(*test_case[0])), [:quarta, test_case[1].map { |result_part| cards_arr(*result_part) }]]
    end
    test_function func, data
    
    # quartas.each do |quarta_hand, result|
      # found_sequence = announce.find_quarta(hand(*cards_arr(*quarta_hand)))
      # found_sequence.should eq result
    # end
    
    no_announces = [
      %w[h10 cj d9 hq d10 h9 s7 d8],
      %w[s9 h8 d10 hq ca c7 d8 s10],
      %w[sa sk sq hj s10 s9 s8],
    ]
    
    no_announces.each do |some_hand, result|
      found_sequence = announce.find_quarta(hand(*cards_arr(*some_hand)))
      found_sequence.should eq []
    end
  end
  
  it 'finds thertas' do
    thertas = [
      [%w[sa sk sq ha h10 h9 cq c8], [:therta, cards_arr(*%w[sa sk sq])]],
      [%w[c8 sk s9 h7 c7 d8 d10 c9], [:therta, cards_arr(*%w[c8 c7 c9])]],
      [%w[hj ha hk h10 h7 h9 c9 d8], [:therta, cards_arr(*%w[hj h10 h9])]],
    ]
    
    thertas.each do |therta_hand, result|
      found_sequence = announce.find_therta(hand(*cards_arr(*therta_hand)))
      found_sequence.should eq result
    end
    
    found_therta = announce.find_therta hand(*cards_arr(*%w[ca ck cq h8 h9 c10 c9 c8]))
    found_therta.should eq [:therta, cards_arr(*%w[ca ck cq]), cards_arr(*%w[c10 c9 c8])]
    
    no_announces = [
      [%w[h10 cj d9 hq ca h9 s7 d8], []],
      [%w[s9 h8 d10 hq ca c7 d8 s10], []],
    ]
    
    no_announces.each do |some_hand, result|
      found_sequence = announce.find_therta(hand(*cards_arr(*some_hand)))
      found_sequence.should eq result
    end
  end
  
  it 'finds carres' do
    carres = [
      [%w[sj dj hj cj s9 h9 d9 c9], [:carre, :jack, :r9]],
      [%w[h10 h9 s10 sa s7 c10 c8 d10], [:carre, :r10]],
    ]
    
    carres.each do |carre_hand, result|
      found_carres = announce.find_carre(hand(*cards_arr(*carre_hand)))
      found_carres.should eq result
    end
  end
  
  it 'finds belote' do
    belotes = [
      [%w[sq h9 s10 sj dj ck dq sk], [:belote, cards_arr(*%w[sq sk])]],
      [%w[sq hk cq dk hq ck dq sk], [:belote, cards_arr(*%w[sq sk]), cards_arr(*%w[hk hq]), cards_arr(*%w[dk dq]), cards_arr(*%w[cq ck])]],
    ]
    
    belotes.each do |belote_hand, result|
      found_belotes = announce.find_belote(hand(*cards_arr(*belote_hand)))
      found_belotes.should eq result
    end
  end
  
  it 'finds all announces' do
    hands = [
      [
        %w[sa sk sq sj s10 hq hj h10],
        [[:belote, cards_arr(*%w[sk sq])], [:quinta, cards_arr(*%w[sa sk sq sj s10])], [:therta, cards_arr(*%w[hq hj h10])]]
      ],
      [
        %w[s7 d7 s8 d10 s9 hk ha cj], [[:therta, cards_arr(*%w[s7 s8 s9])]]
      ],
    ]
    
    hands.each do |some_hand, result|
      found_annons = announce.announces(hand(*cards_arr(*some_hand)))
      found_annons.should eq result
    end
  end
end
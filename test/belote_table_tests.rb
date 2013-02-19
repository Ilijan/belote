describe "Player" do
  it 'initialize properly' do
    lambda { Player.new 'KolioMasta' }.should_not raise_error StandardError 
    
    lambda { Player.new }.should raise_error ArgumentError
  end
end
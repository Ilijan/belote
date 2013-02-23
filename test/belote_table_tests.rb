describe "Player" do
  it 'initialize properly' do
    lambda { Player.new 'KolioMasta' }.should_not raise_error StandardError 
    
    lambda { Player.new }.should raise_error ArgumentError
  end
end

describe "BeloteTable" do
  it 'initialize properly' do
    lambda do
      BeloteTable.new
      # BeloteTable.new Player.new('Riki')
      # BeloteTable.new Player.new('One'), Player.new('Two')
      # BeloteTable.new Player.new('One'), Player.new('Two'), Player.new('Three')
      # BeloteTable.new Player.new('One'), Player.new('Two'), Player.new('Three'), Player.new('Four')
    end.should_not raise_error StandardError
    
    lambda do
      BeloteTable.new Player.new('One'), Player.new('Two'), Player.new('Three'), Player.new('Four'), Player.new('Helper')
    end.should raise_error ArgumentError
  end
end

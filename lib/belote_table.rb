require 'card'

class Player
  attr_reader :name
  attr_accessor :hand

  def initialize(name)
    @name = name
    @hand = Hand.new
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

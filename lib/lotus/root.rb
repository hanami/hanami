require 'lotus/environment'

module Lotus
  def self.root
    Lotus::Environment.new.root
  end    
end
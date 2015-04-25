require 'pathname'

module Lotus
  def self.root
    Lotus::Configuration.new.root
  end    
end
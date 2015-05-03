require 'pathname'

module Lotus
  def self.root
    Pathname.new(Dir.pwd)
  end    
end
require 'hanami/environment'

module Hanami
  def self.root
    Hanami::Environment.new.root
  end    
end
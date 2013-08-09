$:.unshift 'lib'
require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'lotus'

Minitest::Test.class_eval do
  def self.isolate_me!
    require 'minitest/isolation'

    class << self
      unless method_defined?(:isolation?)
        define_method :isolation? do true end
      end
    end
  end
end

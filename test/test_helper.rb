require 'rubygems'
require 'bundler/setup'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name 'test'
    add_filter   'test'
  end
end

FIXTURES_ROOT = Pathname(File.dirname(__FILE__) + '/fixtures').realpath

require 'minitest/autorun'
$:.unshift 'lib'
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

Lotus::Config::LoadPaths.class_eval do
  def clear
    @paths.clear
  end

  def include?(object)
    @paths.include?(object)
  end

  def empty?
    @paths.empty?
  end
end

Lotus::Middleware.class_eval { attr_reader :stack }

Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop/app/templates').mkpath

require 'fixtures'

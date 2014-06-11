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

require 'minitest/autorun'
$:.unshift 'lib'
require 'lotus'

Lotus::Config::LoadPaths.class_eval do
  def clear
    @paths.clear
  end

  def include?(object)
    @paths.include?(object)
  end
end

Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop/app/templates').mkpath
require 'fixtures'

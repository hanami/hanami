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

Lotus::Application.class_eval do
  def self.clear_registered_applications!
    synchronize do
      applications.clear
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

class FakeRackBuilder
  attr_reader :stack

  def initialize(&blk)
    @stack = Set.new
    instance_eval(&blk) if block_given?
  end

  def use(middleware)
    @stack.add(middleware)
  end
end

class DependenciesReporter
  LOTUS_GEMS = [
    'lotus-utils',
    'lotus-validations',
    'lotus-router',
    'lotus-model',
    'lotus-view',
    'lotus-controller'
  ].freeze

  def initialize
    @dependencies = dependencies
  end

  def run
    return unless ENV['TRAVIS']

    dependencies.each do |dep|
      source = dep.source
      puts "#{ dep.name } - #{ source.revision }"
    end
  end

  private
  def dependencies
    Bundler.environment.dependencies.find_all do |dep|
      LOTUS_GEMS.include?(dep.name)
    end
  end
end

DependenciesReporter.new.run

def stub_stdout_constant
  begin_block = <<-BLOCK
    original_verbosity = $VERBOSE
    $VERBOSE = nil

    origin_stdout = STDOUT
    STDOUT = StringIO.new
  BLOCK
  TOPLEVEL_BINDING.eval begin_block

  yield
  return_str = STDOUT.string

  ensure_block = <<-BLOCK
    STDOUT = origin_stdout
    $VERBOSE = original_verbosity
  BLOCK
  TOPLEVEL_BINDING.eval ensure_block

  return_str
end


def stub_time_now
  Time.stub :now, Time.utc(1988, 9, 1, 0, 0, 0) do
    yield
  end
end

$pwd = Dir.pwd
require 'fixtures'

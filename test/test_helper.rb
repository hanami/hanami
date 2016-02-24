require_relative './support/helper'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatters =[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name 'test'
    add_filter   'test'
  end
end

# Skip MRI specifc specs
require 'minispec-metadata'
MinispecMetadata.add_tag_string('~engine:mri') if RUBY_ENGINE != 'ruby'

Minitest::Test.class_eval do
  def with_temp_dir(name = 'test_app', &block)
    current_dir = Dir.pwd
    temp_dir = Dir.mktmpdir
    app_dir = File.join(temp_dir, name)

    FileUtils.mkdir_p(app_dir)

    begin
      Dir.chdir(app_dir) do
        yield(Pathname.new(current_dir))
      end
    ensure
      FileUtils.rm_r(temp_dir)
    end
  end


  def self.isolate_me!
    require 'minitest/isolation'

    class << self
      unless method_defined?(:isolation?)
        define_method :isolation? do true end
      end
    end
  end
end

Minitest.after_run do
  hanamirc = Pathname.new(__dir__ + '/../.hanamirc')
  hanamirc.delete if hanamirc.exist?
end

Hanami::Application.class_eval do
  def self.clear_registered_applications!
    synchronize do
      applications.clear
    end
  end
end

Hanami::Config::LoadPaths.class_eval do
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

Hanami::Middleware.class_eval { attr_reader :stack }

Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop/app/templates').mkpath
Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop/app/templates/mailers').mkpath
Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop/config/initializers/').mkpath

File.open("#{File.dirname(__FILE__)}/../tmp/coffee_shop/config/initializers/init1.rb", 'w') { |f| f.write('class CollaborationInitializer1; end;') }
File.open("#{File.dirname(__FILE__)}/../tmp/coffee_shop/config/initializers/init2.rb", 'w') { |f| f.write('class CollaborationInitializer2; end;') }

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
  HANAMI_GEMS = [
    'hanami-utils',
    'hanami-validations',
    'hanami-router',
    'hanami-model',
    'hanami-view',
    'hanami-controller',
    'hanami-mailer',
    'hanami-assets'
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
      HANAMI_GEMS.include?(dep.name)
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

require 'fixtures'

class Minitest::IsolatedEach
  include Enumerable

  def initialize(tests)
    @tests = tests
  end

  def each
    @tests.each do |test|
      isolate do
        yield test
      end
    end
  end

  def isolate
    pid = fork do
      yield
    end

    Process.wait(pid)
  end
end

module Minitest
  class << self
    remove_method :__run
  end

  class Test
    def capture_exceptions
      yield
    end
  end

  def self.__run reporter, options
    suites = Runnable.runnables
    isolation, serial = suites.partition { |s| s.respond_to?(:isolation?) && s.isolation? }

    IsolatedEach.new(isolation).map { |suite| suite.run reporter, options } +
      serial.map { |suite| suite.run reporter, options }
  end
end

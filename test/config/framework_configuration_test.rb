require 'test_helper'

describe Hanami::Config::FrameworkConfiguration do
  describe '#__apply' do
    it 'allows to instantiate without a block' do
      framework = FakeFrameworkConfiguration.new
      config    = Hanami::Config::FrameworkConfiguration.new

      config.__apply(framework)

      framework.prefix.must_be_nil
      framework.suffix.must_be_nil
    end

    it 'applies block passed to constructor' do
      expected  = '/admin'
      framework = FakeFrameworkConfiguration.new
      config    = Hanami::Config::FrameworkConfiguration.new do
        prefix expected
      end

      config.__apply(framework)

      framework.prefix.must_equal(expected)
      framework.suffix.must_be_nil
    end

    it 'applies block passed with __add' do
      expected  = '.rb'
      framework = FakeFrameworkConfiguration.new
      config    = Hanami::Config::FrameworkConfiguration.new

      config.__add { suffix expected }
      config.__apply(framework)

      framework.prefix.must_be_nil
      framework.suffix.must_equal expected
    end

    it 'applies Prock passed with __add' do
      expected  = '.css'
      framework = FakeFrameworkConfiguration.new
      config    = Hanami::Config::FrameworkConfiguration.new

      config.__add(&Proc.new { suffix expected })
      config.__apply(framework)

      framework.prefix.must_be_nil
      framework.suffix.must_equal expected
    end

    it 'block passed with __add takes priority over initialize' do
      expected_prefix = '/metrics'
      expected_suffix = '.js'

      framework = FakeFrameworkConfiguration.new
      config    = Hanami::Config::FrameworkConfiguration.new do
        prefix '/admin'
        suffix expected_suffix
      end

      config.__add { prefix expected_prefix }
      config.__apply(framework)

      framework.prefix.must_equal expected_prefix
      framework.suffix.must_equal expected_suffix
    end
  end

  describe '#__add' do
    it 'returns self' do
      config = Hanami::Config::FrameworkConfiguration.new
      actual = config.__add { }

      actual.must_equal config
    end
  end
end

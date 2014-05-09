require 'test_helper'

describe Lotus::Config::LoadingPaths do
  describe '#initialize' do
    it 'can be initialized with zero paths' do
      paths = Lotus::Config::LoadingPaths.new
      paths.must_be_empty
    end

    it 'can be initialized with one path' do
      paths = Lotus::Config::LoadingPaths.new '..'
      paths.must_include '..'
    end

    it 'can be initialized with more paths' do
      paths = Lotus::Config::LoadingPaths.new '..', '../..'
      paths.must_include '..'
      paths.must_include '../..'
    end
  end

  describe '#each' do
    it 'coerces the given paths to pathnames and yields a block' do
      paths = Lotus::Config::LoadingPaths.new '..', '../..'

      paths.each do |path|
        path.must_be_kind_of Pathname
      end
    end

    it 'remove duplicates' do
      paths   = Lotus::Config::LoadingPaths.new '..', '..'
      paths.each(&Proc.new{}).size.must_equal 1
    end

    it 'raises an error if a path is unknown' do
      paths = Lotus::Config::LoadingPaths.new 'unknown/path'

      -> {
        paths.each { }
      }.must_raise Errno::ENOENT
    end
  end
end

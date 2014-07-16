require 'test_helper'

describe Lotus::Config::Sessions do
  describe '#enabled?' do
    it 'is false unless identifier is provided' do
      sessions = Lotus::Config::Sessions.new
      sessions.wont_be :enabled?
    end

    it 'is true when identifier is provided' do
      sessions = Lotus::Config::Sessions.new('Cookie')
      sessions.must_be :enabled?
    end
  end

  describe '#middleware' do
    it 'provided with identifier returns passed options' do
      options = { domain: 'example.com' }
      sessions = Lotus::Config::Sessions.new('Cookie', options)
      sessions.middleware[1].must_equal [options]
    end

    describe 'provided with class as identifier' do
      before do
        SessionMiddleware = Class.new
      end

      after do
        Object.send(:remove_const, :SessionMiddleware)
      end

      it 'returns class' do
        sessions = Lotus::Config::Sessions.new(SessionMiddleware)
        sessions.middleware.first.must_equal SessionMiddleware
      end
    end

    describe 'provided with string as identifier' do
      it 'returns string' do
        sessions = Lotus::Config::Sessions.new('SessionMiddleware')
        sessions.middleware.first.must_equal 'SessionMiddleware'
      end
    end

    describe 'provided with symbol as identifier' do
      it 'returns symbol as class name under Rack::Session namespace' do
        sessions = Lotus::Config::Sessions.new(:some_storage)
        sessions.middleware.first.must_equal 'Rack::Session::SomeStorage'
      end
    end
  end
end

require 'test_helper'

describe Hanami::Config::Sessions do
  describe '#enabled?' do
    it 'is false unless identifier is provided' do
      sessions = Hanami::Config::Sessions.new
      sessions.wont_be :enabled?
    end

    it 'is true when identifier is provided' do
      sessions = Hanami::Config::Sessions.new('Cookie')
      sessions.must_be :enabled?
    end
  end

  describe '#middleware' do
    before do
      SessionMiddleware = Class.new
    end

    after do
      Object.send(:remove_const, :SessionMiddleware)
    end

    describe 'provided with class as identifier' do
      it 'returns class' do
        sessions = Hanami::Config::Sessions.new(SessionMiddleware)
        sessions.middleware.must_equal [SessionMiddleware, {}]
      end
    end

    describe 'provided with string as identifier' do
      it 'returns string' do
        sessions = Hanami::Config::Sessions.new('SessionMiddleware')
        sessions.middleware.must_equal ['SessionMiddleware', {}]
      end
    end

    describe 'provided with symbol as identifier' do
      before do
        module Rack::Session
          class SomeStorage
          end
        end
      end

      after do
        Rack::Session.__send__(:remove_const, :SomeStorage)
      end

      it 'returns symbol as class name under Rack::Session namespace' do
        sessions = Hanami::Config::Sessions.new(:some_storage)
        sessions.middleware.must_equal ['Rack::Session::SomeStorage', {}]
      end
    end

    describe 'with options' do
      it 'returns passed options' do
        options = { domain: 'example.com' }
        sessions = Hanami::Config::Sessions.new('Cookie', options)
        sessions.middleware.must_equal ['Cookie', options]
      end
    end
  end
end

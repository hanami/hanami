require 'test_helper'

describe 'lotus/setup' do
  describe 'when required' do
    before do
      ENV['LOTUS_ENV'] = ENV['RACK_ENV'] = nil

      Lotus::Utils::IO.silence_warnings do
        @bundler = Bundler

        Bundler = Module.new do
          extend self

          def require(*groups)
            @required_groups = groups
          end

          def required_groups
            @required_groups
          end

        end
      end

      require 'lotus/setup'
    end

    after do
      Lotus::Utils::IO.silence_warnings do
        Bundler = @bundler
      end
    end

    it 'requires Bundler groups' do
      env = Lotus::Environment.new
      Bundler.required_groups.must_equal(env.bundler_groups)
    end

  end
end

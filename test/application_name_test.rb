require 'test_helper'
require 'hanami/application_name'

describe Hanami::ApplicationName do
  describe 'formats' do
    describe '#to_s' do
      it 'renders downcased' do
        application_name = Hanami::ApplicationName.new('MY-APP')
        application_name.to_s.must_equal 'my_app'
      end

      it 'renders trimmed' do
        application_name = Hanami::ApplicationName.new(' my-app ')
        application_name.to_s.must_equal 'my_app'
      end

      it 'renders internal spaces as underscores' do
        application_name = Hanami::ApplicationName.new('my app')
        application_name.to_s.must_equal 'my_app'
      end
    end

    describe '#to_env_s' do
      it 'renders uppercased with non-alphanumeric characters as underscores' do
        application_name = Hanami::ApplicationName.new('my-app')
        application_name.to_env_s.must_equal 'MY_APP'
      end
    end
  end

  describe 'reserved words' do
    it 'prohibits "hanami"' do
      exception = -> { Hanami::ApplicationName.new('hanami') }.must_raise RuntimeError
      exception.message.must_equal "application name must not be any one of the following: hanami"
    end

    describe '.invalid?' do
      describe 'when name is "hanami"' do
        it 'returns true' do
          Hanami::ApplicationName.invalid?('hanami').must_equal true
        end
      end
    end
  end
end

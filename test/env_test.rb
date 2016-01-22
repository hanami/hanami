require 'test_helper'

describe 'Hanami' do
  before do
    ENV['HANAMI_ENV'] = 'test'
  end

  describe '.env' do
    it 'returns environment name' do
      Hanami.env.must_equal 'test'
    end
  end

  describe '.env?' do
    describe 'when environment is matched' do
      describe 'when single name' do
        describe 'when environment var is symbol' do
          it 'returns true' do
            Hanami.env?(:test).must_equal true
          end
        end
        describe 'when environment var is string' do
          it 'returns true' do
            Hanami.env?("test").must_equal true
          end
        end
      end

      describe 'when multiple names' do
        describe 'when environment vars are symbol' do
          it 'returns true' do
            Hanami.env?(:development, :test, :production).must_equal true
          end
        end
        describe 'when environment vars are string' do
          it 'returns true' do
            Hanami.env?("development", "test", "production").must_equal true
          end
        end

        describe 'when environment vars include string and symbol' do
          it 'returns true' do
            Hanami.env?(:development, "test", "production").must_equal true
          end
        end
      end
    end

    describe 'when environment is not matched' do
      before do
        ENV['HANAMI_ENV'] = 'development'
      end

      describe 'when single name' do
        describe 'when environment var is symbol' do
          it 'returns false' do
            Hanami.env?(:test).must_equal false
          end
        end
        describe 'when environment var is string' do
          it 'returns false' do
            Hanami.env?("test").must_equal false
          end
        end
      end

      describe 'when multiple names' do
        describe 'when environment vars are symbol' do
          it 'returns false' do
            Hanami.env?(:test, :production).must_equal false
          end
        end
        describe 'when environment vars are string' do
          it 'returns false' do
            Hanami.env?("test", "production").must_equal false
          end
        end

        describe 'when environment vars include string and symbol' do
          it 'returns false' do
            Hanami.env?(:test, "production").must_equal false
          end
        end
      end
    end
  end
end

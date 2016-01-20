require 'test_helper'

describe Hanami::Config::Routes do
  describe '#to_proc' do
    describe 'when only path is given' do
      before do
        @routes = Hanami::Config::Routes.new(Pathname.new(__dir__), path)
      end

      describe "and it's nil" do
        let(:path) { nil }

        it 'raises error' do
          assert_raises ArgumentError do
            @routes.to_proc
          end
        end
      end

      describe "and it points to an unknown file" do
        let(:path) { 'unknown/path' }

        it 'raises error' do
          assert_raises ArgumentError do
            @routes.to_proc
          end
        end
      end

      describe "and it points to a valid file" do
        let(:path) { __dir__ + '/../fixtures/routes' }

        it 'raises error' do
          assert_kind_of Proc, @routes.to_proc
        end
      end
    end
  end
end

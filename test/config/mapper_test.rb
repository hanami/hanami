require 'test_helper'

describe Hanami::Config::Mapper do
  describe '#to_proc' do
    describe 'when only path is given' do
      before do
        @mapping = Hanami::Config::Mapper.new(Pathname.new(__dir__), path)
      end

      describe "and it's nil" do
        let(:path) { nil }

        it 'raises error' do
          assert_raises ArgumentError do
            @mapping.to_proc
          end
        end
      end

      describe "and it points to an unknown file" do
        let(:path) { 'unknown/path' }

        it 'raises error' do
          assert_raises ArgumentError do
            @mapping.to_proc
          end
        end
      end

      describe "and it points to a valid file" do
        let(:path) { __dir__ + '/../fixtures/mapper' }

        it 'raises error' do
          assert_kind_of Proc, @mapping.to_proc
        end
      end
    end
  end
end

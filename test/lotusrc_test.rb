require 'test_helper'

describe Lotus::Lotusrc do
  describe '#options' do
    describe 'file exists' do
      before do
        Dir.chdir($pwd)
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/lotusrc/exists'
        @root = Pathname.new(Dir.pwd)
        @lotusrc = Lotus::Lotusrc.new(@root)
      end

      after do
        Dir.chdir @old_pwd
      end

      describe "#exists?" do
        it 'retuns true' do
          Lotus::Lotusrc.new(@root).exists?.must_equal true
        end
      end

      it 'get values in the file' do
        options = @lotusrc.options
        options[:architecture].must_equal 'container'
        options[:test].must_equal 'minitest'
        options[:template_engine].must_equal 'erb'
      end

      # Bug: https://github.com/lotus/lotus/issues/243
      it "doesn't pollute ENV" do
        ENV.key?('architecture').must_equal false
        ENV.key?('test').must_equal false
        ENV.key?('template_engine').must_equal false
      end
    end

    describe "file doesn't exist" do
      before do
        Dir.chdir($pwd)
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/lotusrc/no_exists'
        @root = Pathname.new(Dir.pwd)
      end

      after do
        Dir.chdir @old_pwd
      end

      describe "#exists?" do
        it 'retuns false' do
          Lotus::Lotusrc.new(@root).exists?.must_equal false
        end
      end

      describe 'default values' do
        before do
          @lotusrc = Lotus::Lotusrc.new(@root)
        end

        it 'reads the file' do
          options = @lotusrc.options
          options[:architecture].must_equal 'container'
          options[:test].must_equal 'minitest'
          options[:template_engine].must_equal 'erb'
        end
      end
    end

    describe 'legacy' do
      before do
        Dir.chdir($pwd)
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/lotusrc/legacy'
        @root = Pathname.new(Dir.pwd)
      end

      after do
        Dir.chdir @old_pwd
      end

      describe "#exists?" do
        it 'retuns false' do
          Lotus::Lotusrc.new(@root).options[:template_engine].must_equal 'slim'
        end
      end
    end
  end
end

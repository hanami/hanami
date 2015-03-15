require 'test_helper'

describe Lotus::Lotusrc do
  describe '#read' do
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

      it 'get values in the file' do
        options = @lotusrc.read
        options[:architecture].must_equal 'container'
        options[:test].must_equal 'minitest'
        options[:template].must_equal 'erb'
      end

      it 'get values although arguments are passed' do
        options = { architecture: 'application', test: 'rspec', template: 'slim' }
        lotusrc = Lotus::Lotusrc.new(@root, options)
        options = lotusrc.read
        options[:architecture].must_equal 'container'
        options[:test].must_equal 'minitest'
        options[:template].must_equal 'erb'
      end
    end

    describe "file doesn't exist" do
      before do
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/lotusrc/no_exists'
        @root = Pathname.new(Dir.pwd)
      end

      after do
        Dir.chdir @old_pwd
      end

      describe 'default values' do
        before do
          @file = Pathname.new(Dir.pwd).join('.lotusrc')
          @lotusrc = Lotus::Lotusrc.new(@root)
        end

        after do
          File.delete(@file)
        end

        it 'read the file' do
          options = @lotusrc.read
          options[:architecture].must_equal 'container'
          options[:test].must_equal 'minitest'
          options[:template].must_equal 'erb'
        end
      end

      describe 'custom values' do
        before do
          @file = Pathname.new(Dir.pwd).join('.lotusrc')
          options = { architecture: 'application', test: 'rspec', template: 'slim' }
          @lotusrc = Lotus::Lotusrc.new(@root, options)
        end

        after do
          File.delete(@file)
        end

        it 'read the file' do
          options = @lotusrc.read
          options[:architecture].must_equal 'application'
          options[:test].must_equal 'rspec'
          options[:template].must_equal 'slim'
        end
      end
    end
  end
end

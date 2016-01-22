require 'test_helper'

describe Hanami::Hanamirc do
  describe '#options' do
    before do
      Dir.chdir($pwd)
      @old_pwd = Dir.pwd
      Dir.chdir hanamirc_path
      @root = Pathname.new(Dir.pwd)
      @hanamirc = Hanami::Hanamirc.new(@root)
    end

    after do
      Dir.chdir @old_pwd
    end

    describe 'file exists' do
      let(:hanamirc_path) { 'test/fixtures/hanamirc/exists' }

      describe "#exists?" do
        it 'retuns true' do
          @hanamirc.exists?.must_equal true
        end
      end

      it 'get values in the file' do
        options = @hanamirc.options
        options[:architecture].must_equal 'container'
        options[:test].must_equal 'minitest'
        options[:template].must_equal 'erb'
      end

      # Bug: https://github.com/hanami/hanami/issues/243
      it "doesn't pollute ENV" do
        ENV.key?('architecture').must_equal false
        ENV.key?('test').must_equal false
        ENV.key?('template').must_equal false
      end

      it 'returns only environment options' do
        allowed_keys = %i[architecture test template]
        options = @hanamirc.options
        options.keys.must_equal allowed_keys
      end
    end

    describe "file doesn't exist" do
      let(:hanamirc_path) { 'test/fixtures/hanamirc/no_exists' }

      describe "#exists?" do
        it 'retuns false' do
          @hanamirc.exists?.must_equal false
        end
      end

      describe 'default values' do
        it 'reads the file' do
          options = @hanamirc.options
          options[:architecture].must_equal 'container'
          options[:test].must_equal 'minitest'
          options[:template].must_equal 'erb'
        end
      end
    end
  end
end

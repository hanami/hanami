require 'test_helper'

#require 'lotus/helpers/asset_uri_helpers.rb'
require 'pry'
#
# # Prepare mock for Application-wise configuration-object
# class AssetUriHelpersMixinTarget::Application
#   def self.configuration
#     @@application_configuration_mock ||= Minitest::Mock.new
#   end
# end

# Prepare minimal mixin-target-class as local test-helper
class AssetUriHelpersMixinTarget
  class Application
    def self.configuration; self; end
    def self.assets; self; end

    def self.reset_config(conf = {}); @@mocked_attributes = conf; end
    def self.method_missing(attr_name); @@mocked_attributes[attr_name] || nil; end
  end

  include Lotus::Helpers::AssetUriHelpers
end

describe Lotus::Helpers::AssetUriHelpers do
  before do
    @mixin_target = AssetUriHelpersMixinTarget.new
  end

  describe 'asset_path' do
    before do
      def AssetUriHelpersMixinTarget::Application::scheme; 'http'; end
      def AssetUriHelpersMixinTarget::Application::domain; 'lotusrb.org'; end
      def AssetUriHelpersMixinTarget::Application::port; end
      def AssetUriHelpersMixinTarget::Application::prefix; end
    end

    describe 'without prefix set' do
      before do
      end

      it 'returns an absolute reference to the assets-directory if called without parameter' do
        @mixin_target.asset_path().must_equal '/assets/'
      end

      it 'assembles an array-parameter with one element to an absolute asset-reference with the single array-element as filename' do
        @mixin_target.asset_path(['flat-file.txt']).must_equal '/assets/flat-file.txt'
      end

      it 'assembles an array with many elementes to an absolute subdirectory-reference with the last array-element as appended filename' do
        @mixin_target.asset_path(
          [:this, :is, :a, :deep, :directory, :structure, 'flat-file.txt']
        ).must_equal('/assets/this/is/a/deep/directory/structure/flat-file.txt')
      end

      it 'assembles a single string-parameter to an absolute asset-reference with the single parameter as filename' do
        @mixin_target.asset_path('super-file-name.txt').must_equal '/assets/super-file-name.txt'
      end

      it 'raises an ArgumentError if the argument is not kind of String or Array' do
        proc {
          @mixin_target.asset_path(5)
        }.must_raise ArgumentError

        proc {
          @mixin_target.asset_path( {fancy_path: 'i/am/hip'} )
        }.must_raise ArgumentError
      end
    end


    describe 'with prefix set to "admin/"' do
      it 'returns an absolute reference to the assets/admin-directory if called without parameter' do
        @mixin_target.asset_path().must_equal '/assets/admin/'
      end
    end
  end

  describe 'asset_url' do
    it 'returns an absolute url to the assets-directory if called without parameters' do
      @mixin_target.asset_url().must_equal 'http://lotusrb.org/assets/'
    end
  end
end

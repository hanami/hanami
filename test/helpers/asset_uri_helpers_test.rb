require 'test_helper'

#require 'lotus/helpers/asset_uri_helpers.rb'
require_relative 'helpers_test_helpers'

# Prepare minimal mixin-target-class as local test-helper
class AssetUriHelpersMixinTarget
  include HelpersTestHelpers::ConfigStub

  include Lotus::Helpers::AssetUriHelpers
end

describe Lotus::Helpers::AssetUriHelpers do
  before do
    @mixin_target = AssetUriHelpersMixinTarget.new
  end

  describe 'asset_path' do
    describe 'without prefix set' do
      before do
        AssetUriHelpersMixinTarget::Application.reset_config({
          scheme: 'http',
          host: 'lotusrb.org',
          port: 0
        })
        AssetUriHelpersMixinTarget::Assets.reset_config prefix: ''
      end

      it 'returns an absolute reference to the assets-directory if called without parameter' do
        @mixin_target.asset_path().must_equal('/assets/')
      end

      it 'assembles an array-parameter with one element to an absolute asset-reference with the single array-element as filename' do
        @mixin_target.asset_path(['flat-file.txt']).must_equal('/assets/flat-file.txt')
      end

      it 'assembles an array with many elementes to an absolute subdirectory-reference with the last array-element as appended filename' do
        @mixin_target.asset_path(
          [:this, :is, :a, :deep, :directory, :structure, 'flat-file.txt']
        ).must_equal('/assets/this/is/a/deep/directory/structure/flat-file.txt')
      end

      it 'assembles a single string-parameter to an absolute asset-reference with the single parameter as filename' do
        @mixin_target.asset_path('super-file-name.txt').must_equal '/assets/super-file-name.txt'
      end
    end

    describe 'with prefix set to "admin/"' do
      before do
        AssetUriHelpersMixinTarget::Application.reset_config({
          scheme: 'http',
          host: 'lotusrb.org',
          port: 0
        })
        AssetUriHelpersMixinTarget::Assets.reset_config prefix: 'admin/'
      end

      it 'returns an absolute reference to the assets/admin-directory if called without parameter' do
        @mixin_target.asset_path().must_equal('/assets/admin/')
      end
    end
  end

  describe 'asset_url' do
    describe 'without prefix set' do
      before do
        AssetUriHelpersMixinTarget::Application.reset_config({
          scheme: 'http',
          host: 'lotusrb.org',
          port: 0
        })
        AssetUriHelpersMixinTarget::Assets.reset_config prefix: ''
      end

      it 'returns an absolute url to the assets-directory if called without parameters' do
        @mixin_target.asset_url().must_equal('http://lotusrb.org/assets/')
      end

      it 'returns an absolute url to an asset if called with a filename' do
        @mixin_target.asset_url('fancy-file.name.md').must_equal('http://lotusrb.org/assets/fancy-file.name.md')
      end
    end

    describe 'with prefix set to "admin/"' do
      before do
        AssetUriHelpersMixinTarget::Application.reset_config({
          scheme: 'http',
          host: 'lotusrb.org',
          port: 0
        })
        AssetUriHelpersMixinTarget::Assets.reset_config prefix: 'admin/'
      end

      it 'returns an absolute url to the prefixed assets-directory if called without parameters' do
        @mixin_target.asset_url().must_equal('http://lotusrb.org/assets/admin/')
      end

      it 'returns an absolute url to a prefixed asset if called with a filename' do
        @mixin_target.asset_url('fancy-file.name.md').must_equal( 'http://lotusrb.org/assets/admin/fancy-file.name.md')
      end
    end

    describe 'with custom scheme, host or port' do
      it 'returns a https-url to "this.is.my.lotusrb.org" and port "8080"' do
        AssetUriHelpersMixinTarget::Application.reset_config({
          scheme: 'https',
          host: 'this.is.my.lotusrb.org',
          port: 8080
        })
        AssetUriHelpersMixinTarget::Assets.reset_config prefix: ''

        @mixin_target.asset_url().must_equal('https://this.is.my.lotusrb.org:8080/assets/')
      end

      # FIXME: Unicode-domains currently not working due to missing punycode-converter

      # it 'returns a ftp-url to the unicode-domain "tüpfelhyänenöhrchen.de" and port "22"' do
      #   AssetUriHelpersMixinTarget::Application.reset_config({
      #     scheme: 'ftp',
      #     host: 'tüpfelhyänenöhrchen.de',
      #     port: '22'
      #   })
      #
      #   @mixin_target.asset_url().must_equal('ftp://tüpfelhyänenöhrchen.de:22/assets/')
      # end
    end
  end
end

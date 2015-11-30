require 'test_helper'

#require 'lotus/helpers/asset_uri_helpers.rb'

# Prepare minimal mixin-target-class as local test-helper
class AssetUriHelpersMixinTarget
  include Lotus::Helpers::AssetUriHelpers
end

describe Lotus::Helpers::AssetUriHelpers do
  before do
    @mixin_target = AssetUriHelpersMixinTarget.new
  end

  describe 'asset_path' do
  end
end

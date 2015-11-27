require 'test_helper'

class ImageHelperView
  include Lotus::View
  include Lotus::Helpers::AssetTagHelpers
  attr_reader :params

  def initialize(params)
    @params = Lotus::Action::Params.new(params)
  end
end

describe Lotus::Helpers::AssetTagHelpers do
  let(:view)   { ImageHelperView.new(params) }
  let(:params) { Hash[] }

  describe 'image' do
    it 'render an img tag' do
      view.image('application.jpg').to_s.must_equal %(<img src=\"/assets/application.jpg\" alt=\"Application\">)
    end

    it 'custom alt' do
      view.image('application.jpg', alt: 'My Alt').to_s.must_equal %(<img alt=\"My Alt\" src=\"/assets/application.jpg\">)
    end

    it 'custom data attribute' do
      view.image('application.jpg', 'data-user-id' => 5).to_s.must_equal %(<img data-user-id=\"5\" src=\"/assets/application.jpg\" alt=\"Application\">)
    end
  end
end
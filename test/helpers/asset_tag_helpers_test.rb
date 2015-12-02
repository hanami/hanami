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

  describe '#favicon' do
    it 'renders' do
      view.favicon.to_s.must_equal %(<link href="/assets/favicon.ico" rel="shortcut icon" type="image/x-icon">)
    end

    it 'renders with HTML attributes' do
      view.favicon('favicon.png', rel: 'icon', type: 'image/png').to_s.must_equal %(<link rel="icon" type="image/png" href="/assets/favicon.png">)
    end
  end

  describe '#video' do
    it 'renders' do
      tag = view.video('movie.mp4')
      tag.to_s.must_equal %(<video src="/assets/movie.mp4"></video>)
    end

    it 'renders with html attributes' do
      tag = view.video('movie.mp4', autoplay: true, controls: true)
      tag.to_s.must_equal %(<video autoplay="autoplay" controls="controls" src="/assets/movie.mp4"></video>)
    end

    it 'renders with fallback content' do
      tag = view.video('movie.mp4') do
        "Your browser does not support the video tag"
      end
      tag.to_s.must_equal %(<video src="/assets/movie.mp4">\nYour browser does not support the video tag\n</video>)
    end

    it 'renders with tracks' do
      tag = view.video('movie.mp4') do
        track kind: 'captions', src: view.asset_path('movie.en.vtt'), srclang: 'en', label: 'English'
      end
      tag.to_s.must_equal %(<video src="/assets/movie.mp4">\n<track kind="captions" src="/assets/movie.en.vtt" srclang="en" label="English">\n</video>)
    end

    it 'renders with sources' do
      tag = view.video do
        text "Your browser does not support the video tag"
        source src: view.asset_path('movie.mp4'), type: 'video/mp4'
        source src: view.asset_path('movie.ogg'), type: 'video/ogg'
      end
      tag.to_s.must_equal %(<video>\nYour browser does not support the video tag\n<source src="/assets/movie.mp4" type="video/mp4">\n<source src="/assets/movie.ogg" type="video/ogg">\n</video>)
    end

    it 'raises an exception when no arguments' do
      -> {view.video()}.must_raise ArgumentError
    end

    it 'raises an exception when no src and no block' do
      -> {view.video(content: true)}.must_raise ArgumentError
    end
  end

  describe 'favicon' do
    it 'renders a default icon' do
      tag = view.favicon
      tag.to_s.must_equal %(<link href="/assets/favicon.ico" rel="shortcut icon" type="image/x-icon">)
    end

    it 'renders an icon from optional path' do
      tag = view.favicon('myfavicon.ico')
      tag.to_s.must_equal %(<link href="/assets/myfavicon.ico" rel="shortcut icon" type="image/x-icon">)
    end
  end
end

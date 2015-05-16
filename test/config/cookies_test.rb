require 'test_helper'

describe Lotus::Config::Cookies do
  describe '#enabled?' do
    it "is false when cookies aren't enabled" do
      cookies = Lotus::Config::Cookies.new
      cookies.enabled?.must_equal false
      cookies = Lotus::Config::Cookies.new(false)
      cookies.enabled?.must_equal false
    end

    it 'is true when cookies are enabled' do
      cookies = Lotus::Config::Cookies.new(true)
      cookies.enabled?.must_equal true
    end
  end

  describe "#options" do
    it 'get options if they are passed' do
      options = { domain: 'lotusrb.org', path: '/controller', secure: true, httponly: true }
      cookies = Lotus::Config::Cookies.new(true, options)
      cookies.default_options.must_equal options
    end

    it 'return httponly and secure by default' do
      cookies = Lotus::Config::Cookies.new(true)
      cookies.default_options.must_equal({ httponly: true, secure: false })
    end

    it 'disabling httponly' do
      cookies = Lotus::Config::Cookies.new(true, { httponly: false })
      cookies.default_options.must_equal({ httponly: false, secure: false })
    end

    it 'enabling secure by default' do
      configuration = Lotus::Configuration.new
      configuration.scheme 'https'
      cookies = Lotus::Config::Cookies.new(true, {}, configuration)
      cookies.default_options.must_equal({ httponly: true, secure: true })
    end

    it 'disabling secure with scheme https' do
      configuration = Lotus::Configuration.new
      configuration.scheme 'https'
      cookies = Lotus::Config::Cookies.new(true, { secure: false }, configuration)
      cookies.default_options.must_equal({ httponly: true, secure: false })
    end

    it 'enabling secure with scheme http' do
      configuration = Lotus::Configuration.new
      configuration.scheme 'http'
      cookies = Lotus::Config::Cookies.new(true, { secure: true }, configuration)
      cookies.default_options.must_equal({ httponly: true, secure: true })
    end
  end
end

require 'test_helper'

describe Lotus::Config::Cookies do
  let(:config) { Lotus::Configuration.new }

  describe '#enabled?' do
    it "is false when cookies aren't enabled" do
      cookies = Lotus::Config::Cookies.new(config)
      cookies.enabled?.must_equal false

      cookies = Lotus::Config::Cookies.new(config, false)
      cookies.enabled?.must_equal false
    end

    it 'is true when cookies are enabled' do
      cookies = Lotus::Config::Cookies.new(config, true)
      cookies.enabled?.must_equal true
    end

    it 'is true if options are passed' do
      cookies = Lotus::Config::Cookies.new(config, max_age: 300)
      cookies.enabled?.must_equal true
    end
  end

  describe "#options" do
    it 'get options if they are passed' do
      options = { domain: 'lotusrb.org', path: '/controller', secure: true, httponly: true }
      cookies = Lotus::Config::Cookies.new(config, options)
      cookies.default_options.must_equal options
    end

    it 'return httponly and secure by default' do
      cookies = Lotus::Config::Cookies.new(config, true)
      cookies.default_options.must_equal({ httponly: true, secure: false })
    end

    it 'disabling httponly' do
      cookies = Lotus::Config::Cookies.new(config, httponly: false)
      cookies.default_options.must_equal({ httponly: false, secure: false })
    end

    it 'enabling secure by default' do
      config.scheme 'https'
      cookies = Lotus::Config::Cookies.new(config, {})

      cookies.default_options.must_equal({ httponly: true, secure: true })
    end

    it 'disabling secure with scheme https' do
      config.scheme 'https'
      cookies = Lotus::Config::Cookies.new(config, { secure: false })

      cookies.default_options.must_equal({ httponly: true, secure: false })
    end

    it 'enabling secure with scheme http' do
      config.scheme 'http'
      cookies = Lotus::Config::Cookies.new(config, { secure: true })

      cookies.default_options.must_equal({ httponly: true, secure: true })
    end
  end
end

# frozen_string_literal: true

require "hanami/config/actions"

RSpec.describe Hanami::Config::Actions, "#content_security_policy" do
  let(:app_config) { Hanami::Config.new(app_name: "MyApp::App", env: :development) }
  let(:config) { app_config.actions }
  subject(:content_security_policy) { config.content_security_policy }

  context "no CSP config specified" do
    it "has defaults" do
      expect(content_security_policy[:base_uri]).to eq("'self'")

      expected = [
        %(base-uri 'self'),
        %(child-src 'self'),
        %(connect-src 'self'),
        %(default-src 'none'),
        %(font-src 'self'),
        %(form-action 'self'),
        %(frame-ancestors 'self'),
        %(frame-src 'self'),
        %(img-src 'self' https: data:),
        %(media-src 'self'),
        %(object-src 'none'),
        %(script-src 'self'),
        %(style-src 'self' 'unsafe-inline' https:)
      ].join(";")

      expect(content_security_policy.to_s).to eq(expected)
    end
  end

  context "CSP settings specified" do
    let(:cdn_url) { "https://assets.hanamirb.test" }

    it "appends to default values" do
      content_security_policy[:script_src] += " #{cdn_url}"

      expect(content_security_policy[:script_src]).to eq("'self' #{cdn_url}")
      expect(content_security_policy.to_s).to match("'self' #{cdn_url}")
    end

    it "overrides default values" do
      content_security_policy[:style_src] = cdn_url

      expect(content_security_policy[:style_src]).to eq(cdn_url)
      expect(content_security_policy.to_s).to match(cdn_url)
    end

    it "nullifies value" do
      content_security_policy[:object_src] = nil

      expect(content_security_policy[:object_src]).to be(nil)
      expect(content_security_policy.to_s).to match("object-src ;")
    end

    it "deletes key" do
      content_security_policy.delete(:object_src)

      expect(content_security_policy[:object_src]).to be(nil)
      expect(content_security_policy.to_s).to_not match("object-src")
    end

    it "adds a custom key" do
      content_security_policy[:a_custom_key] = "foo"

      expect(content_security_policy[:a_custom_key]).to eq("foo")
      expect(content_security_policy.to_s).to match("a-custom-key foo")
    end
  end

  context "with CSP enabled" do
    it "sets default header" do
      app_config.finalize!

      expect(config.default_headers.fetch("Content-Security-Policy")).to eq(content_security_policy.to_s)
    end
  end

  context "with CSP disabled" do
    it "doesn't set default header" do
      config.content_security_policy = false
      app_config.finalize!

      expect(config.default_headers.key?("Content-Security-Policy")).to be(false)
    end
  end
end

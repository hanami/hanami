# frozen_string_literal: true

require "hanami/configuration/actions"

RSpec.describe Hanami::Configuration::Actions, "#content_security_policy" do
  let(:configuration) { described_class.new }
  subject(:content_security_policy) { configuration.content_security_policy }

  context "no CSP config specified" do
    context "without assets_server_url" do

      it "has defaults" do
        expect(content_security_policy[:base_uri]).to eq("'self'")

        expected = [
          %(base-uri 'self';),
          %(child-src 'self';),
          %(connect-src 'self';),
          %(default-src 'none';),
          %(font-src 'self';),
          %(form-action 'self';),
          %(frame-ancestors 'self';),
          %(frame-src 'self';),
          %(img-src 'self' https: data:;),
          %(media-src 'self';),
          %(object-src 'none';),
          %(plugin-types application/pdf;),
          %(script-src 'self';),
          %(style-src 'self' 'unsafe-inline' https:)
        ].join("\n")

        expect(content_security_policy.to_str).to eq(expected)
      end
    end

    context "with assets_server_url" do
      let(:configuration) { described_class.new(assets_server_url: assets_server_url) }
      let(:assets_server_url) { "http://localhost:8080" }

      it "includes server url" do
        expect(content_security_policy[:script_src]).to eq("'self' #{assets_server_url}")
        expect(content_security_policy[:style_src]).to eq("'self' 'unsafe-inline' https: #{assets_server_url}")
      end
    end
  end

  context "CSP settings specified" do
    let(:cdn_url) { "https://assets.hanamirb.test" }

    it "appends to default values" do
      content_security_policy[:script_src] += " #{cdn_url}"

      expect(content_security_policy[:script_src]).to eq("'self' #{cdn_url}")
      expect(content_security_policy.to_str).to match("'self' #{cdn_url}")
    end

    it "overrides default values" do
      content_security_policy[:style_src] = cdn_url

      expect(content_security_policy[:style_src]).to eq(cdn_url)
      expect(content_security_policy.to_str).to match(cdn_url)
    end

    it "nullifies value" do
      content_security_policy[:plugin_types] = nil

      expect(content_security_policy[:plugin_types]).to be(nil)
      expect(content_security_policy.to_str).to match("plugin-types ;")
    end

    it "deletes key" do
      content_security_policy.delete(:object_src)

      expect(content_security_policy[:object_src]).to be(nil)
      expect(content_security_policy.to_str).to_not match("object-src")
    end

    it "adds a custom key" do
      content_security_policy[:a_custom_key] = "foo"

      expect(content_security_policy[:a_custom_key]).to eq("foo")
      expect(content_security_policy.to_str).to match("a-custom-key foo")
    end
  end

  context "with CSP enabled" do
    it "sets default header" do
      configuration.finalize!

      expect(configuration.default_headers.fetch("Content-Security-Policy")).to eq(content_security_policy.to_str)
    end
  end

  context "with CSP disabled" do
    it "doesn't set default header" do
      configuration.content_security_policy = false
      configuration.finalize!

      expect(configuration.default_headers.key?("Content-Security-Policy")).to be(false)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.security" do
    it "returns default" do
      app = Class.new(described_class)
      subject = app.config.security

      expect(subject).to be_kind_of(Hanami::Configuration::Security)

      expect(subject.x_frame_options).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.x_frame_options.header).to eq("X-Frame-Options")
      expect(subject.x_frame_options.value).to eq("DENY")

      expect(subject.x_content_type_options).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.x_content_type_options.header).to eq("X-Content-Type-Options")
      expect(subject.x_content_type_options.value).to eq("nosniff")

      expect(subject.x_xss_protection).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.x_xss_protection.header).to eq("X-XSS-Protection")
      expect(subject.x_xss_protection.value).to eq("1; mode=block")

      expect(subject.content_security_policy).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.content_security_policy.header).to eq("Content-Security-Policy")
      expect(subject.content_security_policy.value).to eq("form-action 'self'; frame-ancestors 'self'; base-uri 'self'; default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline' https:; font-src 'self'; object-src 'none'; plugin-types application/pdf; child-src 'self'; frame-src 'self'; media-src 'self'")
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.security.x_frame_options = "sameorigin"
        config.security.x_content_type_options = nil
        config.security.x_xss_protection = "1"
        config.security.content_security_policy[:style_src] += " https://my.cdn.example"
        config.security.content_security_policy[:plugin_types] = nil
      end
      subject = app.config.security

      expect(subject).to be_kind_of(Hanami::Configuration::Security)

      expect(subject.x_frame_options).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.x_frame_options.header).to eq("X-Frame-Options")
      expect(subject.x_frame_options.value).to eq("sameorigin")

      expect(subject.x_content_type_options).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.x_content_type_options.header).to eq("X-Content-Type-Options")
      expect(subject.x_content_type_options.value).to be(nil)

      expect(subject.x_xss_protection).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.x_xss_protection.header).to eq("X-XSS-Protection")
      expect(subject.x_xss_protection.value).to eq("1")

      expect(subject.content_security_policy).to be_kind_of(Hanami::Configuration::Security::Setting)
      expect(subject.content_security_policy[:style_src]).to eq("'self' 'unsafe-inline' https: https://my.cdn.example")
      expect(subject.content_security_policy[:plugin_types]).to be(nil)
      expect(subject.content_security_policy.header).to eq("Content-Security-Policy")
      expect(subject.content_security_policy.value).to eq("form-action 'self'; frame-ancestors 'self'; base-uri 'self'; default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline' https: https://my.cdn.example; font-src 'self'; object-src 'none'; child-src 'self'; frame-src 'self'; media-src 'self'")
    end
  end
end

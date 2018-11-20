# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.security" do
    it "returns default" do
      app = Class.new(described_class)
      subject = app.config.security

      expect(subject).to be_kind_of(Hanami::Configuration::Security)
      expect(subject.x_frame_options).to eq("DENY")
      expect(subject.x_content_type_options).to eq("nosniff")
      expect(subject.x_xss_protection).to eq("1; mode=block")
      expect(subject.content_security_policy).to eq(
        form_action: "'self'",
        frame_ancestors: "'self'",
        base_uri: "'self'",
        default_src: "'none'",
        script_src: "'self'",
        connect_src: "'self'",
        img_src: "'self' https: data:",
        style_src: "'self' 'unsafe-inline' https:",
        font_src: "'self'",
        object_src: "'none'",
        plugin_types: "application/pdf",
        child_src: "'self'",
        frame_src: "'self'",
        media_src: "'self'"
      )
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
      expect(subject.x_frame_options).to eq("sameorigin")
      expect(subject.x_content_type_options).to be(nil)
      expect(subject.x_xss_protection).to eq("1")
      expect(subject.content_security_policy[:style_src]).to eq("'self' 'unsafe-inline' https: https://my.cdn.example")
      expect(subject.content_security_policy[:plugin_types]).to be(nil)
    end
  end
end

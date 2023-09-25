# frozen_string_literal: true

require "hanami/config/actions"

RSpec.describe Hanami::Config::Actions, "default values" do
  let(:app_config) { Hanami::Config.new(app_name: "MyApp::App", env: :development) }
  subject(:config) { app_config.actions }

  describe "sessions" do
    specify { expect(config.sessions).not_to be_enabled }
  end

  describe "name_inference_base" do
    specify { expect(config.name_inference_base).to eq "actions" }
  end

  describe "view_name_inferrer" do
    specify { expect(config.view_name_inferrer).to eq Hanami::Slice::ViewNameInferrer }
  end

  describe "view_name_inference_base" do
    specify { expect(config.view_name_inference_base).to eq "views" }
  end

  describe "new default values applied to base action settings" do
    describe "content_security_policy" do
      specify { expect(config.content_security_policy).to be_kind_of(Hanami::Config::Actions::ContentSecurityPolicy) }
    end

    describe "default_headers" do
      specify {
        app_config.finalize!

        expect(config.default_headers).to eq(
          "X-Frame-Options" => "DENY",
          "X-Content-Type-Options" => "nosniff",
          "X-XSS-Protection" => "1; mode=block",
          "Content-Security-Policy" => config.content_security_policy.to_s
        )
      }
    end
  end
end

require "hanami/configuration/actions"

RSpec.describe Hanami::Configuration::Actions, "default values" do
  subject(:configuration) { described_class.new }

  describe "sessions" do
    specify { expect(configuration.sessions).not_to be_enabled }
  end

  describe "name_inference_base" do
    specify { expect(configuration.name_inference_base).to eq "actions" }
  end

  describe "view_context_identifier" do
    specify { expect(configuration.view_context_identifier).to eq "view.context" }
  end

  describe "view_name_inferrer" do
    specify { expect(configuration.view_name_inferrer).to eq Hanami::Application::Action::ViewNameInferrer }
  end

  describe "view_name_inference_base" do
    specify { expect(configuration.view_name_inference_base).to eq "views" }
  end

  describe "new default values applied to base action settings" do
    describe "default_request_format" do
      specify { expect(configuration.default_request_format).to eq :html }
    end

    describe "default_response_format" do
      specify { expect(configuration.default_response_format).to eq :html }
    end

    describe "content_security_policy" do
      specify { expect(configuration.content_security_policy).to be_kind_of(Hanami::Configuration::Actions::ContentSecurityPolicy) }
    end

    describe "default_headers" do
      specify {
        configuration.finalize!

        expect(configuration.default_headers).to eq(
          "X-Frame-Options" => "DENY",
          "X-Content-Type-Options" => "nosniff",
          "X-XSS-Protection" => "1; mode=block",
          "Content-Security-Policy" => configuration.content_security_policy.to_str
        )
      }
    end
  end
end

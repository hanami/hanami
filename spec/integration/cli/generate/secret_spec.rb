RSpec.describe "hanami generate", type: :cli do
  describe "secret" do
    context "without application name" do
      it "prints secret" do
        with_project do
          generate "secret"

          expect(out).to match(/[\w]{64}/)
        end
      end
    end

    context "with application name" do
      it "prints secret" do
        with_project do
          generate "secret web"

          expect(out).to match(%r{WEB_SESSIONS_SECRET="[\w]{64}"})
        end
      end
    end
  end # secret
end

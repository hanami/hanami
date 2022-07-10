# frozen_string_literal: true

RSpec.describe "hanami generate", type: :integration do
  describe "secret" do
    context "without app name" do
      it "prints secret" do
        with_project do
          generate "secret"

          expect(out).to match(/\w{64}/)
        end
      end
    end

    context "with app name" do
      it "prints secret" do
        with_project do
          generate "secret web"

          expect(out).to match(/WEB_SESSIONS_SECRET="\w{64}"/)
        end
      end
    end

    it "prints help message" do
      with_project do
        banner = <<~OUT
          Command:
            hanami generate secret

          Usage:
            hanami generate secret [APP]

          Description:
            Generate session secret

          Arguments:
            APP                               # The app name (eg. `web`)

          Options:
            --help, -h                        # Print this help

          Examples:
        OUT

        output = [
          banner
          # %r{  hanami generate secret     # Prints secret (eg. `[\w]{64}`)},
          # %r{  hanami generate secret web # Prints session secret (eg. `WEB_SESSIONS_SECRET=[\w]{64}`)}
        ]

        run_cmd "hanami generate secret --help", output
      end
    end
  end
end

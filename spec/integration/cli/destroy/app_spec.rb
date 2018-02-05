RSpec.describe "hanami destroy", type: :integration do
  describe "app" do
    it "destroys app" do
      with_project do
        generate "app admin"

        output = [
          "subtract  .env.test",
          "subtract  .env.development",
          "subtract  config/environment.rb",
          "subtract  config/environment.rb",
          "remove  spec/admin",
          "remove  apps/admin"
        ]

        run_command "hanami destroy app admin", output

        expect(".env.test").to_not        have_file_content(%r{ADMIN_SESSIONS_SECRET})
        expect(".env.development").to_not have_file_content(%r{ADMIN_SESSIONS_SECRET})

        expect("config/environment.rb").to_not have_file_content(%r{mount Admin::Application})
        expect("config/environment.rb").to_not have_file_content("require_relative '../apps/admin/application'")

        expect("public/assets/admin").to_not be_an_existing_path
        expect("public/assets.json").to_not be_an_existing_path

        expect("spec/admin").to_not be_an_existing_path
        expect("apps/admin").to_not be_an_existing_path
      end
    end

    it "destroys app with actions and assets" do
      with_project do
        generate "app api --application-base-url=/api/v1"
        generate "action api home#index"

        asset = File.join("apps", "api", "assets", "javascripts", "application.js")
        touch asset

        hanami "assets precompile"

        output = [
          "subtract  .env.test",
          "subtract  .env.development",
          "subtract  config/environment.rb",
          "subtract  config/environment.rb",
          "remove  public/assets/api/v1",
          "remove  public/assets.json",
          "remove  spec/api",
          "remove  apps/api"
        ]

        run_command "hanami destroy app api", output

        expect(".env.test").to_not        have_file_content(%r{API_SESSIONS_SECRET})
        expect(".env.development").to_not have_file_content(%r{API_SESSIONS_SECRET})

        expect("config/environment.rb").to_not have_file_content(%r{mount Api::Application})
        expect("config/environment.rb").to_not have_file_content("require_relative '../apps/api/application'")

        expect("public/assets/api/v1").to_not be_an_existing_path
        expect("public/assets.json").to_not be_an_existing_path

        expect("spec/api").to_not be_an_existing_path
        expect("apps/api").to_not be_an_existing_path
      end
    end

    it "fails with missing argument" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy app" was called with no arguments
Usage: "hanami destroy app APP"
OUT
        run_command "hanami destroy app", output, exit_status: 1
      end
    end

    it "fails with unknown app" do
      with_project do
        output = <<-OUT
`unknown' is not a valid APP. Please specify one of: `web'
OUT
        run_command "hanami destroy app unknown", output, exit_status: 1
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami destroy app

Usage:
  hanami destroy app APP

Description:
  Destroy an app

Arguments:
  APP                 	# REQUIRED The application name (eg. `web`)

Options:
  --help, -h                      	# Print this help

Examples:
  hanami destroy app admin # Destroy `admin` app
OUT

        run_command 'hanami destroy app --help', output
      end
    end
  end # app
end

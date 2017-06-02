RSpec.describe "hanami destroy", type: :cli do
  describe "app" do
    it "destroys app" do
      with_project do
        generate "app admin"
        # FIXME: fix this when Hanami 1.1 will be out
        # generate "action admin home#index"

        output = [
          "remove  apps/admin/application.rb",
          "remove  apps/admin/config/routes.rb",
          "remove  apps/admin/views/application_layout.rb",
          "remove  apps/admin/templates/application.html.erb",
          "remove  apps/admin/assets/favicon.ico",
          "remove  apps/admin/controllers/.gitkeep",
          "remove  apps/admin/assets/images/.gitkeep",
          "remove  apps/admin/assets/javascripts/.gitkeep",
          "remove  apps/admin/assets/stylesheets/.gitkeep",
          "remove  spec/admin/features/.gitkeep",
          "remove  spec/admin/controllers/.gitkeep",
          "remove  spec/admin/views/application_layout_spec.rb",
          "subtract  config/environment.rb",
          "subtract  config/environment.rb",
          "subtract  .env.development",
          "subtract  .env.test"
        ]

        run_command "hanami destroy app admin", output
      end
    end

    it "fails with missing argument" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy application" was called with no arguments
Usage: "hanami destroy application NAME"
OUT
        run_command "hanami destroy app", output
      end
    end

    xit "fails with unknown app" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy application" was called with no arguments
Usage: "hanami application NAME"
OUT
        run_command "hanami destroy app unknown", output
      end
    end
  end # app
end

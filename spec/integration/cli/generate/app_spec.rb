require 'hanami/utils/string'

RSpec.describe "hanami generate", type: :cli do
  describe "app" do
    context "with app name" do
      it_behaves_like "a new app" do
        let(:input) { "admin" }
      end
    end

    context "with underscored app name" do
      it_behaves_like "a new app" do
        let(:input) { "cool_app" }
      end
    end

    context "with dashed app name" do
      it_behaves_like "a new app" do
        let(:input) { "awesome-app" }
      end
    end

    context "with camel case app name" do
      it_behaves_like "a new app" do
        let(:input) { "CaMElAPp" }
      end
    end

    context "--application-base-url" do
      it "generates app" do
        with_project('bookshelf_generate_app_application_base_url') do
          app      = "api"
          app_name = Hanami::Utils::String.new(app).classify
          output   = [
            "insert  config/environment.rb"
          ]

          run_command "hanami generate app #{app} --application-base-url=/api/v1", output

          #
          # config/environment.rb
          #
          expect("config/environment.rb").to have_file_content(%r{require_relative '../apps/#{app}/application'})
          expect("config/environment.rb").to have_file_content(%r{mount #{app_name}::Application, at: '/api/v1'})
        end
      end

      it "fails with missing argument" do
        with_project('bookshelf_generate_app_missing_application_base_url') do
          output = "`' is not a valid URL"
          run_command "hanami generate app foo --application-base-url=", output, exit_status: 1
        end
      end
    end

    context "erb" do
      it "generates app" do
        with_project('bookshelf_generate_app_erb', template: :erb) do
          app      = "admin"
          app_name = Hanami::Utils::String.new(app).classify
          output   = [
            "create  apps/#{app}/templates/application.html.erb"
          ]

          run_command "hanami generate app #{app}", output

          #
          # apps/admin/templates/application.html.erb
          #
          expect("apps/admin/templates/application.html.erb").to have_file_content <<-END
          <!DOCTYPE html>
          <html>
            <head>
              <title>#{app_name}</title>
              <%= favicon %>
            </head>
            <body>
              <%= yield %>
            </body>
          </html>
END
        end
      end
    end # erb

    context "haml" do
      it "generates app" do
        with_project('bookshelf_generate_app_haml', template: :haml) do
          app      = "admin"
          app_name = Hanami::Utils::String.new(app).classify
          output   = [
            "create  apps/#{app}/templates/application.html.haml"
          ]

          run_command "hanami generate app #{app}", output

          #
          # apps/admin/templates/application.html.haml
          #
          expect("apps/admin/templates/application.html.haml").to have_file_content <<-END
          !!!
          %html
            %head
              %title #{app_name}
              = favicon
            %body
              = yield
END
        end
      end
    end # haml

    context "slim" do
      it "generates app" do
        with_project('bookshelf_generate_app_slim', template: :slim) do
          app      = "admin"
          app_name = Hanami::Utils::String.new(app).classify
          output   = [
            "create  apps/#{app}/templates/application.html.slim"
          ]

          run_command "hanami generate app #{app}", output

          #
          # apps/admin/templates/application.html.slim
          #
          expect("apps/admin/templates/application.html.slim").to have_file_content <<-END
          doctype html
          html
            head
              title
                | #{app_name}
              = favicon
            body
              = yield
END
        end
      end
    end # slim
  end # app
end

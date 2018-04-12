RSpec.describe "hanami new", type: :integration do
  describe "--template" do
    context "erb" do
      it "generates project" do
        project = 'bookshelf_erb'
        output  = [
          "create  apps/web/templates/application.html.erb"
        ]

        run_command "hanami new #{project} --template=erb", output

        within_project_directory(project) do
          #
          # .hanamirc
          #
          expect('.hanamirc').to have_file_content(%r{template=erb})

          #
          # apps/web/templates/application.html.erb
          #
          expect("apps/web/templates/application.html.erb").to have_file_content <<-END
<!DOCTYPE html>
<html>
  <head>
    <title>Web</title>
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
      it "generates project" do
        project = 'bookshelf_erb'
        output  = [
          "create  apps/web/templates/application.html.haml"
        ]

        run_command "hanami new #{project} --template=haml", output

        within_project_directory(project) do
          #
          # .hanamirc
          #
          expect('.hanamirc').to have_file_content(%r{template=haml})

          #
          # apps/web/templates/application.html.haml
          #
          expect("apps/web/templates/application.html.haml").to have_file_content <<-END
!!!
%html
  %head
    %title Web
    = favicon
  %body
    = yield
END
        end
      end
    end # haml

    context "slim" do
      it "generates project" do
        project = 'bookshelf_erb'
        output  = [
          "create  apps/web/templates/application.html.slim"
        ]

        run_command "hanami new #{project} --template=slim", output

        within_project_directory(project) do
          #
          # .hanamirc
          #
          expect('.hanamirc').to have_file_content(%r{template=slim})

          #
          # apps/web/templates/application.html.slim
          #
          expect("apps/web/templates/application.html.slim").to have_file_content <<-END
doctype html
html
  head
    title
      | Web
    = favicon
  body
    = yield
END
        end
      end
    end # slim

    context "missing" do
      it "returns error" do
        output = "`' is not a valid template engine. Please use one of: `erb', `haml', `slim'"

        run_command "hanami new bookshelf --template=", output, exit_status: 1
      end
    end # missing

    context "unknown" do
      it "returns error" do
        output = "`foo' is not a valid template engine. Please use one of: `erb', `haml', `slim'"

        run_command "hanami new bookshelf --template=foo", output, exit_status: 1
      end
    end # unknown
  end # template
end

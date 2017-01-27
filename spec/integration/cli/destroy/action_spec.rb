RSpec.describe "hanami destroy", type: :cli do
  describe "action" do
    it "destroys action" do
      with_project do
        generate "action web books#index"
        output = [
          "remove  spec/web/controllers/books/index_spec.rb",
          "remove  apps/web/controllers/books/index.rb",
          "remove  apps/web/views/books/index.rb",
          "remove  apps/web/templates/books/index.html.erb",
          "remove  spec/web/views/books/index_spec.rb",
          "subtract  apps/web/config/routes.rb"
        ]

        run_command "hanami destroy action web books#index", output

        expect('spec/web/controllers/books/index_spec.rb').to_not be_an_existing_file
        expect('apps/web/controllers/books/index.rb').to_not      be_an_existing_file
        expect('apps/web/views/books/index.rb').to_not            be_an_existing_file
        expect('apps/web/templates/books/index.html.erb').to_not  be_an_existing_file
        expect('spec/web/views/books/index_spec.rb').to_not       be_an_existing_file

        expect('apps/web/config/routes.rb').to_not have_file_content(%r{get '/books', to: 'books#index'})
      end
    end

    it "fails with missing arguments" do
      with_project do
        output = <<-OUT
ERROR: "hanami actions" was called with no arguments
Usage: "hanami action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME"
OUT

        run_command "hanami destroy action", output # , exit_status: 1 FIXME: Thor exit with 0
      end
    end

    it "fails with missing app" do
      with_project('bookshelf_generate_action_without_app') do
        output = <<-OUT
ERROR: "hanami destroy action" was called with arguments ["home#index"]
Usage: "hanami action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME"
OUT

        run_command "hanami destroy action home#index", output # , exit_status: 1 FIXME: Thor exit with 0
      end
    end

    it "fails with unknown app" do
      with_project('bookshelf_generate_action_with_unknown_app') do
        output = "`foo' is not a valid APPLICATION_NAME. Please specify one of: `web'"

        run_command "hanami destroy action foo home#index", output, exit_status: 1
      end
    end

    context "erb" do
      it "destroys action" do
        with_project('bookshelf_destroy_action_erb', template: 'erb') do
          generate "action web authors#index"
          destroy  "action web authors#index"

          output = [
            "remove  apps/web/templates/books/index.html.erb"
          ]

          run_command "hanami destroy action web books#index", output

          expect('apps/web/templates/authors/index.html.erb').to_not be_an_existing_file
        end
      end
    end # erb

    context "haml" do
      it "destroys action" do
        with_project('bookshelf_generate_action_haml', template: 'haml') do
          generate "action web books#index"

          output = [
            "remove  apps/web/templates/books/index.html.haml"
          ]

          run_command "hanami destroy action web books#index", output

          expect('apps/web/templates/books/index.html.haml').to_not be_an_existing_file
        end
      end
    end # haml

    context "slim" do
      it "destroys action" do
        with_project('bookshelf_generate_action_slim', template: 'slim') do
          generate "action web books#index"

          output = [
            "remove  apps/web/templates/books/index.html.slim"
          ]

          run_command "hanami destroy action web books#index", output

          expect('apps/web/templates/books/index.html.slim').to_not be_an_existing_file
        end
      end
    end # slim
  end # action
end

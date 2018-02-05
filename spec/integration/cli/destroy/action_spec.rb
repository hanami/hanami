RSpec.describe "hanami destroy", type: :integration do
  describe "action" do
    it "destroys action" do
      with_project do
        generate "action web books#index"
        output = [
          "subtract  apps/web/config/routes.rb",
          "remove  spec/web/views/books/index_spec.rb",
          "remove  apps/web/templates/books/index.html.erb",
          "remove  apps/web/views/books/index.rb",
          "remove  apps/web/controllers/books/index.rb",
          "remove  spec/web/controllers/books/index_spec.rb"
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

    it "destroys namespaced action" do
      with_project do
        generate "action web api/books#index"
        output = [
          "subtract  apps/web/config/routes.rb",
          "remove  spec/web/views/api/books/index_spec.rb",
          "remove  apps/web/templates/api/books/index.html.erb",
          "remove  apps/web/views/api/books/index.rb",
          "remove  apps/web/controllers/api/books/index.rb",
          "remove  spec/web/controllers/api/books/index_spec.rb"
        ]

        run_command "hanami destroy action web api/books#index", output

        expect('spec/web/controllers/api/books/index_spec.rb').to_not be_an_existing_file
        expect('apps/web/controllers/api/books/index.rb').to_not      be_an_existing_file
        expect('apps/web/views/api/books/index.rb').to_not            be_an_existing_file
        expect('apps/web/templates/api/books/index.html.erb').to_not  be_an_existing_file
        expect('spec/web/views/api/books/index_spec.rb').to_not       be_an_existing_file

        expect('apps/web/config/routes.rb').to_not have_file_content(%r{get '/api/books', to: 'api/books#index'})
      end
    end

    it "destroys action without view" do
      with_project do
        generate "action web home#ping --skip-view --url=/ping"
        output = [
          "subtract  apps/web/config/routes.rb",
          "remove  apps/web/controllers/home/ping.rb",
          "remove  spec/web/controllers/home/ping_spec.rb"
        ]

        run_command "hanami destroy action web home#ping", output

        expect('spec/web/controllers/home/ping_spec.rb').to_not be_an_existing_file
        expect('apps/web/controllers/home/ping.rb').to_not      be_an_existing_file
        expect('apps/web/views/home/ping.rb').to_not            be_an_existing_file
        expect('apps/web/templates/home/ping.html.erb').to_not  be_an_existing_file
        expect('spec/web/views/home/ping_spec.rb').to_not       be_an_existing_file

        expect('apps/web/config/routes.rb').to_not have_file_content(%r{get '/ping', to: 'home#ping'})
      end
    end

    it "fails with missing arguments" do
      with_project do
        output = <<-OUT
ERROR: "hanami destroy action" was called with no arguments
Usage: "hanami destroy action APP ACTION"
OUT

        run_command "hanami destroy action", output, exit_status: 1
      end
    end

    it "fails with missing app" do
      with_project('bookshelf_generate_action_without_app') do
        output = <<-OUT
ERROR: "hanami destroy action" was called with arguments ["home#index"]
Usage: "hanami destroy action APP ACTION"
OUT

        run_command "hanami destroy action home#index", output, exit_status: 1
      end
    end

    it "fails with unknown app" do
      with_project('bookshelf_generate_action_with_unknown_app') do
        output = "`foo' is not a valid APP. Please specify one of: `web'"

        run_command "hanami destroy action foo home#index", output, exit_status: 1
      end
    end

    it "fails with unknown action" do
      with_project('bookshelf_generate_action_with_unknown_action') do
        output = <<-OUT
cannot find `home#index' in `web' application.
please run `hanami routes' to know the existing actions.
OUT

        run_command "hanami destroy action web home#index", output, exit_status: 1
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami destroy action

Usage:
  hanami destroy action APP ACTION

Description:
  Destroy an action from app

Arguments:
  APP                 	# REQUIRED The application name (eg. `web`)
  ACTION              	# REQUIRED The action name (eg. `home#index`)

Options:
  --help, -h                      	# Print this help

Examples:
  hanami destroy action web home#index    # Basic usage
  hanami destroy action admin users#index # Destroy from `admin` app
OUT

        run_command 'hanami destroy action --help', output
      end
    end
  end # action
end

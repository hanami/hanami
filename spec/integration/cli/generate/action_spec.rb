RSpec.describe "hanami generate", type: :integration do
  describe "action" do
    it "generates action" do
      with_project('bookshelf_generate_action') do
        output = [
          "create  spec/web/controllers/authors/index_spec.rb",
          "create  apps/web/controllers/authors/index.rb",
          "create  apps/web/views/authors/index.rb",
          "create  apps/web/templates/authors/index.html.erb",
          "create  spec/web/views/authors/index_spec.rb",
          "insert  apps/web/config/routes.rb"
        ]

        run_command "hanami generate action web authors#index", output

        #
        # apps/web/controllers/authors/index.rb
        #
        expect('apps/web/controllers/authors/index.rb').to have_file_content <<-END
module Web::Controllers::Authors
  class Index
    include Web::Action

    def call(params)
    end
  end
end
END

        #
        # apps/web/views/authors/index.rb
        #
        expect('apps/web/views/authors/index.rb').to have_file_content <<-END
module Web::Views::Authors
  class Index
    include Web::View
  end
end
END

        #
        # apps/web/config/routes.rb
        #
        expect('apps/web/config/routes.rb').to have_file_content(%r{get '/authors', to: 'authors#index'})
      end
    end

    it "generates namespaced action" do
      with_project('bookshelf_generate_action') do
        output = [
          "create  spec/web/controllers/api/authors/index_spec.rb",
          "create  apps/web/controllers/api/authors/index.rb",
          "create  apps/web/views/api/authors/index.rb",
          "create  apps/web/templates/api/authors/index.html.erb",
          "create  spec/web/views/api/authors/index_spec.rb",
          "insert  apps/web/config/routes.rb"
        ]

        run_command "hanami generate action web api/authors#index", output

        #
        # apps/web/controllers/api/authors/index.rb
        #
        expect('apps/web/controllers/api/authors/index.rb').to have_file_content <<-END
module Web::Controllers::Api::Authors
  class Index
    include Web::Action

    def call(params)
    end
  end
end
END

        #
        # apps/web/views/api/authors/index.rb
        #
        expect('apps/web/views/api/authors/index.rb').to have_file_content <<-END
module Web::Views::Api::Authors
  class Index
    include Web::View
  end
end
END

        #
        # apps/web/config/routes.rb
        #
        expect('apps/web/config/routes.rb').to have_file_content(%r{get '/api/authors', to: 'api/authors#index'})
      end
    end

    it "generates non-RESTful actions" do
      with_project do
        run_command "hanami generate action web sessions#sign_out"

        #
        # apps/web/config/routes.rb
        #
        expect('apps/web/config/routes.rb').to have_file_content(%r{get '/sessions/sign_out', to: 'sessions#sign_out'})
      end
    end

    it "fails with missing arguments" do
      with_project('bookshelf_generate_action_without_args') do
        output = <<-OUT
ERROR: "hanami generate action" was called with no arguments
Usage: "hanami generate action APP ACTION"
OUT
        run_command "hanami generate action", output, exit_status: 1
      end
    end

    it "fails with missing app" do
      with_project('bookshelf_generate_action_without_app') do
        output = <<-OUT
ERROR: "hanami generate action" was called with arguments ["home#index"]
Usage: "hanami generate action APP ACTION"
OUT

        run_command "hanami generate action home#index", output, exit_status: 1
      end
    end

    it "fails with unknown app" do
      with_project('bookshelf_generate_action_with_unknown_app') do
        output = "`foo' is not a valid APP. Please specify one of: `web'"

        run_command "hanami generate action foo home#index", output, exit_status: 1
      end
    end

    context "--url" do
      it "generates action" do
        with_project('bookshelf_generate_action_url') do
          output = [
            "insert  apps/web/config/routes.rb"
          ]

          run_command "hanami generate action web home#index --url=/", output

          #
          # apps/web/config/routes.rb
          #
          expect('apps/web/config/routes.rb').to have_file_content(%r{get '/', to: 'home#index'})
        end
      end

      it "fails with missing argument" do
        with_project('bookshelf_generate_action_missing_url') do
          output = "`' is not a valid URL"
          run_command "hanami generate action web books#create --url=", output, exit_status: 1
        end
      end
    end

    context "--skip-view" do
      it "generates action" do
        with_project('bookshelf_generate_action_skip_view') do
          run_command "hanami generate action web status#check --skip-view", <<-OUT
      create  apps/web/controllers/status/check.rb
      create  spec/web/controllers/status/check_spec.rb
      insert  apps/web/config/routes.rb
OUT

          #
          # apps/web/controllers/status/check.rb
          #
          expect('apps/web/controllers/status/check.rb').to have_file_content <<-END
module Web::Controllers::Status
  class Check
    include Web::Action

    def call(params)
      self.body = 'OK'
    end
  end
end
END
        end
      end
    end

    context "--method" do
      it "generates action" do
        with_project('bookshelf_generate_action_method') do
          output = [
            "insert  apps/web/config/routes.rb"
          ]

          run_command "hanami generate action web books#create --method=POST", output

          #
          # apps/web/config/routes.rb
          #
          expect('apps/web/config/routes.rb').to have_file_content(%r{post '/books', to: 'books#create'})
        end
      end

      it "fails with missing argument" do
        with_project('bookshelf_generate_action_missing_method') do
          output = "`' is not a valid HTTP method. Please use one of: `GET' `POST' `PUT' `DELETE' `HEAD' `OPTIONS' `TRACE' `PATCH' `OPTIONS' `LINK' `UNLINK'"
          run_command "hanami generate action web books#create --method=", output, exit_status: 1
        end
      end

      it "fails with unknown argument" do
        with_project('bookshelf_generate_action_uknown_method') do
          output = "`FOO' is not a valid HTTP method. Please use one of: `GET' `POST' `PUT' `DELETE' `HEAD' `OPTIONS' `TRACE' `PATCH' `OPTIONS' `LINK' `UNLINK'"
          run_command "hanami generate action web books#create --method=FOO", output, exit_status: 1
        end
      end
    end

    context "erb" do
      it "generates action" do
        with_project('bookshelf_generate_action_erb', template: 'erb') do
          output = [
            "create  apps/web/templates/books/index.html.erb"
          ]

          run_command "hanami generate action web books#index", output

          #
          # apps/web/templates/books/index.html.erb
          #
          expect('apps/web/templates/books/index.html.erb').to have_file_content <<-END
END

          #
          # spec/web/views/books/index_spec.rb
          #
          expect('spec/web/views/books/index_spec.rb').to have_file_content %r{'apps/web/templates/books/index.html.erb'}
        end
      end
    end # erb

    context "haml" do
      it "generates action" do
        with_project('bookshelf_generate_action_haml', template: 'haml') do
          output = [
            "create  apps/web/templates/books/index.html.haml"
          ]

          run_command "hanami generate action web books#index", output

          #
          # apps/web/templates/books/index.html.haml
          #
          expect('apps/web/templates/books/index.html.haml').to have_file_content <<-END
END

          #
          # spec/web/views/books/index_spec.rb
          #
          expect('spec/web/views/books/index_spec.rb').to have_file_content(%r{'apps/web/templates/books/index.html.haml'})
        end
      end
    end # haml

    context "slim" do
      it "generates action" do
        with_project('bookshelf_generate_action_slim', template: 'slim') do
          output = [
            "create  apps/web/templates/books/index.html.slim"
          ]

          run_command "hanami generate action web books#index", output

          #
          # apps/web/templates/books/index.html.slim
          #
          expect('apps/web/templates/books/index.html.slim').to have_file_content <<-END
END

          #
          # spec/web/views/books/index_spec.rb
          #
          expect('spec/web/views/books/index_spec.rb').to have_file_content %r{'apps/web/templates/books/index.html.slim'}
        end
      end
    end # slim

    context "minitest" do
      it "generates action" do
        with_project('bookshelf_generate_action_minitest', test: 'minitest') do
          output = [
            "create  spec/web/controllers/books/index_spec.rb",
            "create  spec/web/views/books/index_spec.rb"
          ]

          run_command "hanami generate action web books#index", output

          #
          # spec/web/controllers/books/index_spec.rb
          #
          expect('spec/web/controllers/books/index_spec.rb').to have_file_content <<-END
require_relative '../../../spec_helper'

describe Web::Controllers::Books::Index do
  let(:action) { Web::Controllers::Books::Index.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
END

          #
          # spec/web/views/books/index_spec.rb
          #
          expect('spec/web/views/books/index_spec.rb').to have_file_content <<-END
require_relative '../../../spec_helper'

describe Web::Views::Books::Index do
  let(:exposures) { Hash[format: :html] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/books/index.html.erb') }
  let(:view)      { Web::Views::Books::Index.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #format' do
    view.format.must_equal exposures.fetch(:format)
  end
end
END
        end
      end
    end # minitest

    context "rspec" do
      it "generates action" do
        with_project('bookshelf_generate_action_rspec', test: 'rspec') do
          output = [
            "create  spec/web/controllers/books/index_spec.rb",
            "create  spec/web/views/books/index_spec.rb"
          ]

          run_command "hanami generate action web books#index", output

          #
          # spec/web/controllers/books/index_spec.rb
          #
          expect('spec/web/controllers/books/index_spec.rb').to have_file_content <<-END
RSpec.describe Web::Controllers::Books::Index, type: :action do
  let(:action) { described_class.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    expect(response[0]).to eq 200
  end
end
END

          #
          # spec/web/views/books/index_spec.rb
          #
          expect('spec/web/views/books/index_spec.rb').to have_file_content <<-END
RSpec.describe Web::Views::Books::Index, type: :view do
  let(:exposures) { Hash[format: :html] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/books/index.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #format' do
    expect(view.format).to eq exposures.fetch(:format)
  end
end
END
        end
      end
    end # rspec

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami generate action

Usage:
  hanami generate action APP ACTION

Description:
  Generate an action for app

Arguments:
  APP                 	# REQUIRED The application name (eg. `web`)
  ACTION              	# REQUIRED The action name (eg. `home#index`)

Options:
  --url=VALUE                     	# The action URL
  --method=VALUE                  	# The action HTTP method
  --[no-]skip-view                	# Skip view and template, default: false
  --help, -h                      	# Print this help

Examples:
  hanami generate action web home#index                    # Basic usage
  hanami generate action admin home#index                  # Generate for `admin` app
  hanami generate action web home#index --url=/            # Specify URL
  hanami generate action web sessions#destroy --method=GET # Specify HTTP method
  hanami generate action web books#create --skip-view      # Skip view and template
OUT

        run_command 'hanami generate action --help', output
      end
    end
  end # action
end

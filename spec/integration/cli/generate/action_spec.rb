RSpec.describe "hanami generate", type: :cli do
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

    it "fails with missing arguments" do
      with_project('bookshelf_generate_action_without_args') do
        output = <<-OUT
ERROR: "hanami generate actions" was called with no arguments
Usage: "hanami generate action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME"
OUT

        run_command "hanami generate action", output # , exit_status: 1 FIXME: Thor exit with 0
      end
    end

    it "fails with missing app" do
      with_project('bookshelf_generate_action_without_app') do
        output = <<-OUT
ERROR: "hanami generate action" was called with arguments ["home#index"]
Usage: "hanami generate action APPLICATION_NAME CONTROLLER_NAME#ACTION_NAME"
OUT

        run_command "hanami generate action home#index", output # , exit_status: 1 FIXME: Thor exit with 0
      end
    end

    it "fails with unknown app" do
      with_project('bookshelf_generate_action_with_unknown_app') do
        output = "`foo' is not a valid APPLICATION_NAME. Please specify one of: `web'"

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
      create  spec/web/controllers/status/check_spec.rb
      create  apps/web/controllers/status/check.rb
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
require_relative '../../../../apps/web/controllers/books/index'

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
require_relative '../../../../apps/web/views/books/index'

describe Web::Views::Books::Index do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/books/index.html.erb') }
  let(:view)      { Web::Views::Books::Index.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    skip 'This is an auto-generated test. Edit it and add your own tests.'

    # Example
    view.foo.must_equal exposures.fetch(:foo)
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
require_relative '../../../../apps/web/controllers/books/index'

RSpec.describe Web::Controllers::Books::Index do
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
require_relative '../../../../apps/web/views/books/index'

RSpec.describe Web::Views::Books::Index do
  let(:exposures) { Hash[foo: 'bar'] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/books/index.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  it 'exposes #foo' do
    pending 'This is an auto-generated test. Edit it and add your own tests.'

    # Example
    expect(view.foo).to eq exposures.fetch(:foo)
  end
end
END
        end
      end
    end # rspec
  end # action
end

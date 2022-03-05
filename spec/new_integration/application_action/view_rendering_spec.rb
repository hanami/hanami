# frozen_string_literal: true

# require "hanami"
# require "hanami/action"
# require "hanami/view"
# require "slim"

RSpec.describe "View rendering in application actions", :application_integration do
  specify "Views render with a request-specific context object" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/action/base.rb", <<~RUBY
        # auto_register: false

        require "hanami/application/action"

        module TestApp
          module Action
            class Base < Hanami::Application::Action
            end
          end
        end
      RUBY

      write "lib/test_app/view/base.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          module View
            class Base < Hanami::View
            end
          end
        end
      RUBY

      write "lib/test_app/view/context.rb", <<~RUBY
        # auto_register: false

        require "hanami/view/context"

        module TestApp
          module View
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      write "slices/main/lib/action/base.rb", <<~RUBY
        # auto_register: false

        require "test_app/action/base"

        module Main
          module Action
            class Base < TestApp::Action::Base
            end
          end
        end
      RUBY

      write "slices/main/lib/view/base.rb", <<~RUBY
        # auto_register: false

        require "test_app/view/base"

        module Main
          module View
            class Base < TestApp::View::Base
            end
          end
        end
      RUBY

      write "slices/main/lib/view/context.rb", <<~RUBY
        module Main
          module View
            class Context < TestApp::View::Context
              def request
                _options.fetch(:request)
              end

              def response
                _options.fetch(:response)
              end
            end
          end
        end
      RUBY

      write "slices/main/actions/users/show.rb", <<~RUBY
        module Main
          module Actions
            module Users
              class Show < Main::Action::Base
                include Deps[view: "views.users.show"]

                def handle(req, res)
                  res[:job] = "Singer"
                  res[:age] = 0

                  res.render view, name: req.params[:name], age: 51
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/views/users/show.rb", <<~RUBY
        module Main
          module Views
            module Users
              class Show < Main::View::Base
                expose :name, :job, :age
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/templates/users/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}
        - request.params.to_h.values.sort.each do |value|
          p = value
        p = job
        p = age
      SLIM

      require "hanami/setup"
      # byebug
      require "hanami/prepare"

      action = Main::Slice["actions.users.show"]
      response = action.(name: "Jennifer", last_name: "Lopez")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer</h1><p>Jennifer</p><p>Lopez</p><p>Singer</p><p>51</p></body></html>"
    end
  end
end

# frozen_string_literal: true

RSpec.describe "Application action / View rendering", :application_integration do
  specify "Views render with a request-specific context object" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/action.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "lib/test_app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      write "lib/test_app/views/context.rb", <<~RUBY
        # auto_register: false

        require "hanami/view/context"

        module TestApp
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      write "slices/main/lib/view.rb", <<~RUBY
        # auto_register: false

        require "test_app/view"

        module Main
          class View < TestApp::View
          end
        end
      RUBY

      write "slices/main/lib/views/context.rb", <<~RUBY
        module Main
          module Views
            class Context < TestApp::Views::Context
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
              class Show < TestApp::Action
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
              class Show < Main::View
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
      require "hanami/prepare"

      action = Main::Slice["actions.users.show"]
      response = action.(name: "Jennifer", last_name: "Lopez")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer</h1><p>Jennifer</p><p>Lopez</p><p>Singer</p><p>51</p></body></html>"
    end
  end
end

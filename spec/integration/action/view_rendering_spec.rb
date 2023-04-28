# frozen_string_literal: true

RSpec.describe "App action / View rendering", :app_integration do
  specify "Views render with a request-specific context object" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      write "app/actions/users/show.rb", <<~RUBY
        module TestApp
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

      write "app/views/users/show.rb", <<~RUBY
        module TestApp
          module Views
            module Users
              class Show < TestApp::View
                expose :name, :job, :age
              end
            end
          end
        end
      RUBY

      write "app/templates/layouts/app.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "app/templates/users/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}
        - request.params.to_h.values.sort.each do |value|
          p = value
        p = job
        p = age
      SLIM

      require "hanami/prepare"

      action = TestApp::App["actions.users.show"]
      response = action.(name: "Jennifer", last_name: "Lopez")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer</h1><p>Jennifer</p><p>Lopez</p><p>Singer</p><p>51</p></body></html>"
    end
  end
end

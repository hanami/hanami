require "hanami"

RSpec.describe "Application action / View rendering / Automatic rendering", :application_integration do
  it "Renders a view automatically, passing all params and exposures" do
    within_app do
      write "slices/main/actions/profile/show.rb", <<~RUBY
        module Main
          module Actions
            module Profile
              class Show < Main::Action::Base
                def handle(req, res)
                  res[:favorite_number] = 123
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/views/profile/show.rb", <<~RUBY
        module Main
          module Views
            module Profile
              class Show < Main::View::Base
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = Main::Slice["actions.profile.show"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer. Your favorite number is 123, right?</h1></body></html>"
      expect(response.status).to eq 200
    end
  end

  it "Does not render a view automatically when #render? returns false " do
    within_app do
      write "slices/main/actions/profile/show.rb", <<~RUBY
        module Main
          module Actions
            module Profile
              class Show < Main::Action::Base
                def handle(req, res)
                  res[:favorite_number] = 123
                end

                def render?(_res)
                  false
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/views/profile/show.rb", <<~RUBY
        module Main
          module Views
            module Profile
              class Show < Main::View::Base
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = Main::Slice["actions.profile.show"]
      response = action.(name: "Jennifer")

      expect(response.body).to eq []
      expect(response.status).to eq 200
    end
  end

  it "Doesn't render view automatically when body is already assigned" do
    within_app do
      write "slices/main/actions/profile/show.rb", <<~RUBY
        module Main
          module Actions
            module Profile
              class Show < Main::Action::Base
                def handle(req, res)
                  res.body = "200: Okay okay okay"
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/views/profile/show.rb", <<~RUBY
        module Main
          module Views
            module Profile
              class Show < Main::View::Base
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = Main::Slice["actions.profile.show"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "200: Okay okay okay"
      expect(response.status).to eq 200
    end
  end

  it "Doesn't render view automatically when halt is called" do
    within_app do
      write "slices/main/actions/profile/show.rb", <<~RUBY
        module Main
          module Actions
            module Profile
              class Show < Main::Action::Base
                def handle(req, res)
                  halt 404
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/views/profile/show.rb", <<~RUBY
        module Main
          module Views
            module Profile
              class Show < Main::View::Base
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = Main::Slice["actions.profile.show"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "Not Found"
      expect(response.status).to eq 404
    end
  end

  it "Does not render if no view is available" do
    within_app do
      write "slices/main/actions/profile/show.rb", <<~RUBY
        module Main
          module Actions
            module Profile
              class Show < Main::Action::Base
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      action = Main::Slice["actions.profile.show"]
      response = action.({})
      expect(response.body).to eq []
      expect(response.status).to eq 200
    end
  end

  def within_app
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application; end
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

      write "lib/test_app/view/base.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          module View
            class Base < Hanami::View; end
          end
        end
      RUBY

      write "slices/main/lib/view/base.rb", <<~RUBY
        # auto_register: false

        require "test_app/view/base"

        module Main
          module View
            class Base < TestApp::View::Base; end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      yield
    end
  end
end

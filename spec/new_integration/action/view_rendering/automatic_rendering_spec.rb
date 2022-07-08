# frozen_string_literal: true

RSpec.describe "App action / View rendering / Automatic rendering", :app_integration do
  it "Renders a view automatically, passing all params and exposures" do
    within_app do
      write "app/actions/profile/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Profile
              class Show < TestApp::Action
                def handle(req, res)
                  res[:favorite_number] = 123
                end
              end
            end
          end
        end
      RUBY

      write "app/views/profile/show.rb", <<~RUBY
        module TestApp
          module Views
            module Profile
              class Show < TestApp::View
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "app/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = TestApp::App["actions.profile.show"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer. Your favorite number is 123, right?</h1></body></html>"
      expect(response.status).to eq 200
    end
  end

  it "Does not render a view automatically when #render? returns false " do
    within_app do
      write "app/actions/profile/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Profile
              class Show < TestApp::Action
                def handle(req, res)
                  res[:favorite_number] = 123
                end

                def auto_render?(_res)
                  false
                end
              end
            end
          end
        end
      RUBY

      write "app/views/profile/show.rb", <<~RUBY
        module TestApp
          module Views
            module Profile
              class Show < TestApp::View
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "app/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = TestApp::App["actions.profile.show"]
      response = action.(name: "Jennifer")

      expect(response.body).to eq []
      expect(response.status).to eq 200
    end
  end

  it "Doesn't render view automatically when body is already assigned" do
    within_app do
      write "app/actions/profile/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Profile
              class Show < TestApp::Action
                def handle(req, res)
                  res.body = "200: Okay okay okay"
                end
              end
            end
          end
        end
      RUBY

      write "app/views/profile/show.rb", <<~RUBY
        module TestApp
          module Views
            module Profile
              class Show < TestApp::View
                expose :name, :favorite_number
              end
            end
          end
        end
      RUBY

      write "app/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/prepare"

      action = TestApp::App["actions.profile.show"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "200: Okay okay okay"
      expect(response.status).to eq 200
    end
  end

  it "Doesn't render view automatically when halt is called" do
    within_app do
      write "app/actions/profile/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Profile
              class Show < TestApp::Action
                def handle(req, res)
                  halt 404
                end
              end
            end
          end
        end
      RUBY

      write "app/views/profile/show.rb", <<~RUBY
        module TestApp
          module Views
            module Profile
              class Show < TestApp::View
                expose :name
              end
            end
          end
        end
      RUBY

      # This template will crash if not rendered with a valid `name` string. The absence
      # of a crash here tells us that the view was never rendered.
      write "app/templates/profile/show.html.slim", <<~'SLIM'
        h1 Hello, #{name.to_str}!
      SLIM

      require "hanami/prepare"

      # Call the action without a `name` param, thereby ensuring the view will raise an
      # error if rendered
      action = TestApp::App["actions.profile.show"]
      response = action.({})
      rendered = response.body[0]

      aggregate_failures do
        expect(rendered).to eq "Not Found"
        expect(response.status).to eq 404
      end
    end
  end

  it "Does not render if no view is available" do
    within_app do
      write "app/actions/profile/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Profile
              class Show < TestApp::Action
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      action = TestApp::App["actions.profile.show"]
      response = action.({})
      expect(response.body).to eq []
      expect(response.status).to eq 200
    end
  end

  def within_app
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

      write "app/templates/layouts/app.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      yield
    end
  end
end

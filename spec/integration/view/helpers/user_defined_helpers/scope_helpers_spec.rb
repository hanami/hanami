# frozen_string_literal: true

RSpec.describe "App view / Helpers / User-defined helpers / Scope helpers", :app_integration do
  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
            config.layout = nil
          end
        end
      RUBY

      before_app if respond_to?(:before_app)

      require "hanami/prepare"
    end
  end

  describe "app view" do
    def before_app
      write "app/views/helpers.rb", <<~'RUBY'
        # auto_register: false

        module TestApp
          module Views
            module Helpers
              def exclaim_from_app(str)
                "#{str}! (app helper)"
              end
            end
          end
        end
      RUBY

      write "app/views/posts/show.rb", <<~RUBY
        module TestApp
          module Views
            module Posts
              class Show < TestApp::View
              end
            end
          end
        end
      RUBY

      write "app/templates/posts/show.html.erb", <<~ERB
        <h1><%= exclaim_from_app("Hello world") %></h1>
      ERB
    end

    it "makes user-defined helpers available in templates" do
      output = TestApp::App["views.posts.show"].call.to_s.strip
      expect(output).to eq "<h1>Hello world! (app helper)</h1>"
    end
  end

  describe "slice view" do
    def before_app
      write "slices/main/view.rb", <<~RUBY
        module Main
          class View < TestApp::View
            # FIXME: base slice views should override paths from the base app view
            config.paths = [File.join(File.expand_path(__dir__), "templates")]
          end
        end
      RUBY

      write "slices/main/views/helpers.rb", <<~'RUBY'
        # auto_register: false

        module Main
          module Views
            module Helpers
              def exclaim_from_slice(str)
                "#{str}! (slice helper)"
              end
            end
          end
        end
      RUBY

      write "slices/main/views/posts/show.rb", <<~RUBY
        module Main
          module Views
            module Posts
              class Show < Main::View
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/posts/show.html.erb", <<~ERB
        <h1><%= exclaim_from_slice("Hello world") %></h1>
      ERB
    end

    it "makes default helpers available in templates" do
      output = Main::Slice["views.posts.show"].call.to_s.strip
      expect(output).to eq "<h1>Hello world! (slice helper)</h1>"
    end
  end
end

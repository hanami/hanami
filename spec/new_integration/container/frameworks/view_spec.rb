# frozen_string_literal: true

RSpec.describe "Container / Frameworks providers: view", :application_integration do
  specify "View providers are available in application container" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/view/context.rb", <<~RUBY
        # frozen_string_literal: true

        require "hanami/view/context"

        module TestApp
          module View
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      expect(Hanami.application["view.context"]).to be_kind_of(Hanami::View::Context)
    end
  end

  specify "View providers are not available in application container when hanami-view isn't bundled" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.boot

      expect(Hanami.application.key?("view.context")).to be(false)
    end
  end
end

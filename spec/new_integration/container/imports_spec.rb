# frozen_string_literal: true

RSpec.describe "Container imports", :application_integration do
  specify "Application container is imported into slice containers by default" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/admin/.keep", ""

      require "hanami/setup"

      Hanami.init

      shared_service = Object.new
      TestApp::Application.register("shared_service", shared_service)

      Hanami.boot

      expect(Admin::Slice["application.shared_service"]).to be shared_service
    end
  end

  specify "Slices can import other slices" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.slice :admin do
              import :search
            end
          end
        end
      RUBY

      write "slices/admin/.keep", ""

      write "slices/search/lib/index_entity.rb", <<~RUBY
        module Search
          class IndexEntity
          end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      expect(Admin::Slice["search.index_entity"]).to be_a Search::IndexEntity
    end
  end

  specify "Imported components from another slice are lazily resolved in unbooted applications" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.slice :admin do
              import :search
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/test_op.rb", <<~RUBY
        module Admin
          class TestOp
          end
        end
      RUBY

      write "slices/search/lib/index_entity.rb", <<~RUBY
        module Search
          class IndexEntity
          end
        end
      RUBY

      require "hanami/init"

      expect(Hanami.application).not_to be_booted
      expect(Admin::Slice.keys).not_to include "search.index_entity"
      expect(Admin::Slice["search.index_entity"]).to be_a Search::IndexEntity
      expect(Admin::Slice.keys).to include "search.index_entity"
    end
  end
end

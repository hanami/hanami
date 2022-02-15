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

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
          end
        end
      RUBY

      require "hanami/setup"

      Hanami.prepare

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
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            import from: :search
          end
        end
      RUBY

      write "slices/search/lib/index_entity.rb", <<~RUBY
        module Search
          class IndexEntity
          end
        end
      RUBY

      require "hanami/boot"

      expect(Admin::Slice["search.index_entity"]).to be_a Search::IndexEntity

      # Ensure a slice's imported components (e.g. from "application") are not then
      # exported again when that slice is imported, which would result in redundant
      # components
      expect(Search::Slice.key?("application.logger")).to be true
      expect(Admin::Slice.key?("application.logger")).to be true
      expect(Admin::Slice.key?("search.application.logger")).to be false
    end
  end

  specify "Slices can import specific components from other slices" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            import(
              keys: ["query"],
              from: :search
            )
          end
        end
      RUBY

      write "slices/search/lib/index_entity.rb", <<~RUBY
        module Search
          class IndexEntity; end
        end
      RUBY

      write "slices/search/lib/query.rb", <<~RUBY
        module Search
          class Query; end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      expect(Admin::Slice["search.query"]).to be_a Search::Query
    end
  end

  specify "Slices can import from other slices with a custom import key namespace" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            import(
              keys: ["query"],
              from: :search,
              as: :search_engine
            )
          end
        end
      RUBY

      write "slices/search/lib/index_entity.rb", <<~RUBY
        module Search
          class IndexEntity; end
        end
      RUBY

      write "slices/search/lib/query.rb", <<~RUBY
        module Search
          class Query; end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      expect(Admin::Slice["search_engine.query"]).to be_a Search::Query
    end
  end

  specify "Imported components from another slice are lazily resolved in unbooted applications" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            import from: :search
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

      require "hanami/prepare"

      expect(Hanami.application).not_to be_booted

      expect(Admin::Slice.keys).not_to include "search.index_entity"
      expect(Admin::Slice["search.index_entity"]).to be_a Search::IndexEntity
      expect(Admin::Slice.keys).to include "search.index_entity"

      expect(Admin::Slice).not_to be_booted
      expect(Admin::Slice.container).not_to be_finalized
      expect(Search::Slice).not_to be_booted
      expect(Search::Slice.container).not_to be_finalized
    end
  end

  specify "Slices can configure specific exports" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            import(
              keys: %w[index_entity query],
              from: :search
            )
          end
        end
      RUBY

      write "config/slices/search.rb", <<~RUBY
        module Search
          class Slice < Hanami::Slice
            prepare_container do |container|
              container.config.exports = %w[query]
            end
          end
        end
      RUBY

      write "slices/search/lib/index_entity.rb", <<~RUBY
        module Search
          class IndexEntity; end
        end
      RUBY

      write "slices/search/lib/query.rb", <<~RUBY
        module Search
          class Query; end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      expect(Admin::Slice.key?("search.query")).to be true
      expect(Admin::Slice.key?("search.index_entity")).to be false
    end
  end
end

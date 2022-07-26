# frozen_string_literal: true

require "rack/test"

RSpec.describe "Slices / Slice loading", :app_integration do
  describe "loading specific slices" do
    describe "setup app" do
      it "ignores explicitly registered slices not otherwise configured", :aggregate_failures do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.load_slices = %w[admin]
              end
            end
          RUBY

          require "hanami/setup"

          expect { Hanami.app.register_slice :main }.not_to(change { Hanami.app.slices.keys })
          expect { Main }.to raise_error(NameError)

          expect { Hanami.app.register_slice :admin }
            .to change { Hanami.app.slices.keys }
            .to [:admin]
          expect(Admin::Slice).to be
        end
      end
    end

    describe "prepared app" do
      it "only loads the configured slices", :aggregate_failures do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.load_slices = %w[admin]
              end
            end
          RUBY

          write "slices/admin/.keep"
          write "slices/main/.keep"

          require "hanami/prepare"

          expect(Hanami.app.slices.keys).to eq [:admin]
          expect(Admin::Slice).to be
          expect { Main }.to raise_error(NameError)
        end
      end
    end
  end

  describe "skipping specific slices" do
    describe "setup app" do
      it "ignores explicitly registered slices not otherwise configured", :aggregate_failures do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.skip_slices = %w[admin]
              end
            end
          RUBY

          require "hanami/setup"

          expect { Hanami.app.register_slice :admin }.not_to(change { Hanami.app.slices.keys })
          expect { Admin }.to raise_error(NameError)

          expect { Hanami.app.register_slice :main }
            .to change { Hanami.app.slices.keys }
            .to [:main]
          expect(Main::Slice).to be
        end
      end
    end

    describe "prepared app" do
      it "only loads the configured slices", :aggregate_failures do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.skip_slices = %w[admin]
              end
            end
          RUBY

          write "slices/admin/.keep"
          write "slices/main/.keep"

          require "hanami/prepare"

          expect(Hanami.app.slices.keys).to eq [:main]
          expect(Main::Slice).to be
          expect { Admin }.to raise_error(NameError)
        end
      end
    end
  end
end

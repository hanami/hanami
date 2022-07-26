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

      it "prefers load_slices over skip_slices when both are configured" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.load_slices = %w[admin]
                config.slices.skip_slices = %w[admin]
              end
            end
          RUBY

          write "slices/admin/.keep"
          write "slices/main/.keep"

          require "hanami/prepare"

          expect(Hanami.app.slices.keys).to eq [:admin]
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

  describe "using ENV vars" do
    before do
      @orig_env = ENV.to_h
    end

    after do
      ENV.replace(@orig_env)
    end

    it "uses HANAMI_LOAD_SLICES" do
      ENV["HANAMI_LOAD_SLICES"] = "admin"

      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/admin/.keep"
        write "slices/main/.keep"

        require "hanami/setup"

        expect(Hanami.app.config.slices.load_slices).to eq %w[admin]

        require "hanami/prepare"

        expect(Hanami.app.slices.keys).to eq [:admin]
      end
    end

    it "uses HANAMI_SKIP_SLICES" do
      ENV["HANAMI_SKIP_SLICES"] = "admin"

      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/admin/.keep"
        write "slices/main/.keep"

        require "hanami/setup"

        expect(Hanami.app.config.slices.skip_slices).to eq %w[admin]

        require "hanami/prepare"

        expect(Hanami.app.slices.keys).to eq [:main]
      end
    end
  end
end

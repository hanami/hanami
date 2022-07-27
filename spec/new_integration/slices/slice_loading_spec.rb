# frozen_string_literal: true

require "rack/test"

RSpec.describe "Slices / Slice loading", :app_integration, :aggregate_failures do
  let(:app_modules) { %i[TestApp Admin Editorial Main Shop] }

  describe "loading specific slices with config.slices.load_slices" do
    describe "setup app" do
      it "ignores any explicitly registered slices not included in load_slices" do
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

          expect { Hanami.app.register_slice :admin }.to change { Hanami.app.slices.keys }.to [:admin]
          expect(Admin::Slice).to be
        end
      end

      describe "nested slices" do
        it "ignores any explicitly registered slices not included in load_slices" do
          with_tmp_directory(Dir.mktmpdir) do
            write "config/app.rb", <<~'RUBY'
              require "hanami"

              module TestApp
                class App < Hanami::App
                  config.slices.load_slices = %w[admin.shop]
                end
              end
            RUBY

            require "hanami/setup"

            expect { Hanami.app.register_slice :admin }.to change { Hanami.app.slices.keys }.to [:admin]

            expect { Admin::Slice.register_slice :editorial }.not_to(change { Admin::Slice.slices.keys })
            expect { Admin::Slice.register_slice :shop }.to change { Admin::Slice.slices.keys }.to [:shop]
            expect(Shop::Slice).to be
          end
        end
      end
    end

    describe "prepared app" do
      it "loads only the slices included in load_slices" do
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

      it "ignores unknown slices in load_slices" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.load_slices = %w[admin meep morp]
              end
            end
          RUBY

          write "slices/admin/.keep"
          write "slices/main/.keep"

          require "hanami/prepare"

          expect(Hanami.app.slices.keys).to eq [:admin]
        end
      end

      describe "nested slices" do
        it "loads only the dot-delimited nested slices (and their parents) included in load_slices" do
          with_tmp_directory(Dir.mktmpdir) do
            write "config/app.rb", <<~'RUBY'
              require "hanami"

              module TestApp
                class App < Hanami::App
                  config.slices.load_slices = %w[admin.shop]
                end
              end
            RUBY

            write "slices/admin/.keep"
            write "slices/admin/slices/shop/.keep"
            write "slices/admin/slices/editorial/.keep"
            write "slices/main/.keep"

            require "hanami/prepare"

            expect(Hanami.app.slices.keys).to eq [:admin]
            expect(Admin::Slice.slices.keys).to eq [:shop]

            expect(Admin::Slice).to be
            expect(Shop::Slice).to be

            expect { Editorial }.to raise_error(NameError)
            expect { Main }.to raise_error(NameError)
          end
        end
      end
    end
  end

  describe "skipping specific slices with config.slices.skip_slices" do
    describe "setup app" do
      it "skips explicitly registering slices included in skip_slices" do
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

          expect { Hanami.app.register_slice :main }.to change { Hanami.app.slices.keys }.to [:main]
          expect(Main::Slice).to be
        end
      end

      describe "nested slices" do
        it "skips explicity registering slices included in skip_slices" do
          with_tmp_directory(Dir.mktmpdir) do
            write "config/app.rb", <<~'RUBY'
              require "hanami"

              module TestApp
                class App < Hanami::App
                  config.slices.skip_slices = %w[admin.shop]
                end
              end
            RUBY

            require "hanami/setup"

            expect { Hanami.app.register_slice :admin }.to change { Hanami.app.slices.keys }.to [:admin]

            expect { Admin::Slice.register_slice :shop }.not_to(change { Admin::Slice.slices.keys })
            expect { Admin::Slice.register_slice :editorial }.to change { Admin::Slice.slices.keys }.to [:editorial]

            expect(Admin::Slice).to be
            expect(Editorial::Slice).to be
            expect { Shop }.to raise_error(NameError)
          end
        end
      end
    end

    describe "prepared app" do
      it "loads all slices except those in skip_slices", :aggregate_failures do
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

      it "ignores unknown slices in skip_slices" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices.skip_slices = %w[admin meep morp]
              end
            end
          RUBY

          write "slices/admin/.keep"
          write "slices/main/.keep"

          require "hanami/prepare"

          expect(Hanami.app.slices.keys).to eq [:main]
        end
      end

      describe "nested slices" do
        it "loads all child slices of slices except those in skip_slices (using dot-delimited nested slice names)" do
          with_tmp_directory(Dir.mktmpdir) do
            write "config/app.rb", <<~'RUBY'
              require "hanami"

              module TestApp
                class App < Hanami::App
                  config.slices.skip_slices = %w[admin.shop]
                end
              end
            RUBY

            write "slices/admin/.keep"
            write "slices/admin/slices/shop/.keep"
            write "slices/admin/slices/editorial/.keep"
            write "slices/main/.keep"

            require "hanami/prepare"

            expect(Hanami.app.slices.keys).to eq %i[admin main]
            expect(Admin::Slice.slices.keys).to eq [:editorial]

            expect(Admin::Slice).to be
            expect(Editorial::Slice).to be
            expect(Main::Slice).to be

            expect { Shop }.to raise_error(NameError)
          end
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

# frozen_string_literal: true

require "rack/test"

RSpec.describe "Slices / Slice loading", :app_integration, :aggregate_failures do
  let(:app_modules) { %i[TestApp Admin Main] }

  describe "loading specific slices with config.slices" do
    describe "setup app" do
      it "ignores any explicitly registered slices not included in load_slices" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices = %w[admin]
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
                  config.slices = %w[admin.shop]
                end
              end
            RUBY

            require "hanami/setup"

            expect { Hanami.app.register_slice :admin }.to change { Hanami.app.slices.keys }.to [:admin]

            expect { Admin::Slice.register_slice :editorial }.not_to(change { Admin::Slice.slices.keys })
            expect { Admin::Slice.register_slice :shop }.to change { Admin::Slice.slices.keys }.to [:shop]
            expect(Admin::Shop::Slice).to be
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
                config.slices = %w[admin]
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

      it "ignores unknown slices in load_slices" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.slices = %w[admin meep morp]
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
                  config.slices = %w[admin.shop]
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
            expect(Admin::Shop::Slice).to be

            expect { Admin::Editorial }.to raise_error(NameError)
            expect { Main }.to raise_error(NameError)
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

    it "uses HANAMI_SLICES" do
      ENV["HANAMI_SLICES"] = "admin"

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

        expect(Hanami.app.config.slices).to eq %w[admin]

        require "hanami/prepare"

        expect(Hanami.app.slices.keys).to eq [:admin]
      end
    end
  end
end

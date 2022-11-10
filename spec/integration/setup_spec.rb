# frozen_string_literal: true

RSpec.describe "Hanami setup", :app_integration do
  describe "Hanami.setup" do
    shared_examples "hanami setup" do
      it "requires the app file when found" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~RUBY
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          expect { setup }.to change { Hanami.app? }.to true
          expect(Hanami.app).to be TestApp::App
        end
      end

      it "requires the app file when found in a parent directory" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~RUBY
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "lib/foo/bar/.keep"

          Dir.chdir("lib/foo/bar") do
            expect { setup }.to change { Hanami.app? }.to true
            expect(Hanami.app).to be TestApp::App
          end
        end
      end

      it "raises when the app file is not found" do
        with_tmp_directory(Dir.mktmpdir) do
          expect { setup }.to raise_error Hanami::AppLoadError, /Could not locate your Hanami app file/
        end
      end

      it "doesn't raise when the app file is not found but the app is already set" do
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end

        expect { setup }.not_to raise_error
      end

      %w[hanami-view hanami-actions hanami-router].each do |gem_name|
        it "works when #{gem_name} gem is not bundled" do
          allow(Hanami).to receive(:bundled?).and_call_original
          expect(Hanami).to receive(:bundled?).with("hanami-router").and_return(false)

          with_tmp_directory(Dir.mktmpdir) do
            write "config/app.rb", <<~RUBY
              require "hanami"

              module TestApp
                class App < Hanami::App
                end
              end
            RUBY

            expect { setup }.to change { Hanami.app? }.to true
          end
        end
      end
    end

    describe "using hanami/setup require" do
      def setup
        require "hanami/setup"
      end

      it_behaves_like "hanami setup"
    end

    describe "using Hanami.setup method" do
      def setup(...)
        require "hanami"
        Hanami.setup(...)
      end

      it_behaves_like "hanami setup"

      it "returns the loaded app when the app file is found" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~RUBY
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          # Multiple calls return the same app
          expect(setup).to be(Hanami.app)
          expect(setup).to be(Hanami.app)
        end
      end

      it "returns nil when given `raise_exception: false` and the app file is not found" do
        with_tmp_directory(Dir.mktmpdir) do
          expect(setup(raise_exception: false)).to be nil
        end
      end
    end
  end

  describe "Hanami.app_path" do
    subject(:app_path) { Hanami.app_path }

    context "config/app.rb exists in current directory" do
      it "returns its absolute path" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb"

          expect(app_path.to_s).to match(%r{^/.*/config/app.rb$})
        end
      end
    end

    context "config/app.rb exists in a parent directory" do
      it "returns its absolute path" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb"
          write "lib/foo/bar/.keep"

          Dir.chdir("lib/foo/bar") do
            expect(app_path.to_s).to match(%r{^/.*/config/app.rb$})
          end
        end
      end
    end

    context "no app file in any directory" do
      it "returns nil" do
        with_tmp_directory(Dir.mktmpdir) do
          expect(app_path).to be(nil)
        end
      end
    end

    context "directory exists with same name as the app file" do
      it "returns nil" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb/.keep"

          expect(app_path).to be(nil)
        end
      end
    end
  end
end

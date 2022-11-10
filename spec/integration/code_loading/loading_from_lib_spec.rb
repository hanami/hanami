# frozen_string_literal: true

RSpec.describe "Code loading / Loading from lib directory", :app_integration do
  describe "default root" do
    before :context do
      with_directory(@dir = make_tmp_directory.realpath) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "lib/external_class.rb", <<~'RUBY'
          class ExternalClass
          end
        RUBY

        write "lib/test_app/test_class.rb", <<~'RUBY'
          module TestApp
            class TestClass
            end
          end
        RUBY
      end
    end

    context "setup app" do
      before do
        with_directory(@dir) { require "hanami/setup" }
      end

      it "adds the lib directory to the load path" do
        expect($LOAD_PATH).to include(@dir.join("lib").to_s)
      end

      specify "classes in lib/ can be required directly" do
        expect(require("external_class")).to be true
        expect(ExternalClass).to be
      end

      specify "classes in lib/[app_namespace]/ cannot yet be autoloaded" do
        expect { TestApp::TestClass }.to raise_error(NameError)
      end
    end

    context "prepared app" do
      before do
        with_directory(@dir) { require "hanami/prepare" }
      end

      it "leaves the lib directory already in the load path" do
        expect($LOAD_PATH).to include(@dir.join("lib").to_s).exactly(1).times
      end

      specify "classes in lib/[app_namespace]/ can be autoloaded" do
        expect(TestApp::TestClass).to be
      end
    end

    context "lib dir missing" do
      before do
        with_directory(@dir = make_tmp_directory.realpath) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          require "hanami/setup"
        end
      end

      it "does not add the lib directory to the load path" do
        expect($LOAD_PATH).not_to include(@dir.join("lib").to_s)
      end
    end
  end

  describe "default root with requires at top of app file" do
    before :context do
      with_directory(@dir = make_tmp_directory.realpath) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"
          require "external_class"

          module TestApp
            class App < Hanami::App
              @class_from_lib = ExternalClass

              def self.class_from_lib
                @class_from_lib
              end
            end
          end
        RUBY

        write "lib/external_class.rb", <<~'RUBY'
          class ExternalClass
          end
        RUBY
      end
    end

    before do
      with_directory(@dir) { require "hanami/setup" }
    end

    specify "classes in lib/ can be required directly from the top of the app file" do
      expect(Hanami.app.class_from_lib).to be ExternalClass
    end
  end

  context "app root reconfigured" do
    before :context do
      with_directory(@dir = make_tmp_directory.realpath) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.root = Pathname(__dir__).join("..", "src").realpath
            end
          end
        RUBY

        write "src/lib/external_class.rb", <<~'RUBY'
          class ExternalClass
          end
        RUBY

        write "src/lib/test_app/test_class.rb", <<~'RUBY'
          module TestApp
            class TestClass
            end
          end
        RUBY
      end
    end

    context "setup app" do
      before do
        with_directory(@dir) { require "hanami/setup" }
      end

      it "does not add the lib directory to the load path (already done at time of subclassing)" do
        expect($LOAD_PATH).not_to include(@dir.join("src", "lib").to_s)
      end

      it "adds the lib directory under the new root with `prepare_load_path`" do
        expect { Hanami.app.prepare_load_path }
          .to change { $LOAD_PATH }
          .to include(@dir.join("src", "lib").to_s)
      end
    end

    context "prepared app" do
      before do
        with_directory(@dir) { require "hanami/prepare" }
      end

      it "adds the lib directory to the load path" do
        expect($LOAD_PATH).to include(@dir.join("src", "lib").to_s)
      end

      specify "classes in lib/ can be required directly" do
        expect(require("external_class")).to be true
        expect(ExternalClass).to be
      end

      specify "classes in lib/[app_namespace]/ can be autoloaded" do
        expect(TestApp::TestClass).to be
      end
    end
  end

  context "app root reconfigured and load path immediately prepared" do
    before :context do
      with_directory(@dir = make_tmp_directory.realpath) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.root = Pathname(__dir__).join("..", "src").realpath and prepare_load_path
            end
          end
        RUBY

        write "src/lib/external_class.rb", <<~'RUBY'
          class ExternalClass
          end
        RUBY

        write "src/lib/test_app/test_class.rb", <<~'RUBY'
          module TestApp
            class TestClass
            end
          end
        RUBY
      end
    end

    context "setup app" do
      before do
        with_directory(@dir) { require "hanami/setup" }
      end

      it "adds the lib directory to the load path" do
        expect($LOAD_PATH).to include(@dir.join("src", "lib").to_s)
      end

      specify "classes in lib/ can be required directly" do
        expect(require("external_class")).to be true
        expect(ExternalClass).to be
      end

      specify "classes in lib/[app_namespace]/ cannot yet be autoloaded" do
        expect { TestApp::TestClass }.to raise_error(NameError)
      end
    end

    context "prepared app" do
      before do
        with_directory(@dir) { require "hanami/prepare" }
      end

      it "leaves the lib directory to the load path" do
        expect($LOAD_PATH).to include(@dir.join("src", "lib").to_s).exactly(1).times
      end

      specify "classes in lib/[app_namespace]/ can be autoloaded" do
        expect(TestApp::TestClass).to be
      end
    end
  end
end

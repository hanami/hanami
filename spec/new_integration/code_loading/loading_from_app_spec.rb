# frozen_string_literal: true

RSpec.describe "Code loading / Loading from app directory", :app_integration do
  before :context do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/test_class.rb", <<~'RUBY'
        module TestApp
          class TestClass
          end
        end
      RUBY

      write "app/action.rb", <<~'RUBY'
        # auto_register: false

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "app/actions/home/show.rb", <<~'RUBY'
        module TestApp
          module Actions
            module Home
              class Show < TestApp::Action
              end
            end
          end
        end
      RUBY
    end
  end

  before do
    with_directory(@dir) do
      require "hanami/prepare"
    end
  end

  specify "Classes in app/ directory are autoloaded with the app namespace" do
    expect(TestApp::TestClass).to be
    expect(TestApp::Action).to be
    expect(TestApp::Actions::Home::Show).to be
  end

  specify "Classes in app directory are auto-registered" do
    expect(TestApp::App["test_class"]).to be_an_instance_of TestApp::TestClass
    expect(TestApp::App["actions.home.show"]).to be_an_instance_of TestApp::Actions::Home::Show

    # Files with "auto_register: false" magic comments are not auto-registered
    expect(TestApp::App.key?("action")).to be false
  end

  describe "app/lib/ directory" do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/lib/test_class.rb", <<~'RUBY'
          module TestApp
            class TestClass
            end
          end
        RUBY
      end
    end

    specify "Classes in app/lib/ directory are autoloaded with the app namespace" do
      expect(TestApp::TestClass).to be
    end

    specify "Classes in app/lib/ directory are auto-registered" do
      expect(TestApp::App["test_class"]).to be_an_instance_of TestApp::TestClass
    end

    specify "Classes in app/lib/ directory are not redundantly auto-registered under 'lib' key namespace" do
      expect(TestApp::App.key?("lib.test_class")).to be false
    end
  end

  # rubocop:disable Style/GlobalVars
  describe "same-named class defined in both app/ and app/lib/ directories" do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/test_class.rb", <<~'RUBY'
          $app_class_loaded = true

          module TestApp
            class TestClass
              (@loaded_from ||= []) << "app"
            end
          end
        RUBY

        write "app/lib/test_class.rb", <<~'RUBY'
          $app_lib_class_loaded = true

          module TestApp
            class TestClass
              (@loaded_from ||= []) << "app/lib"
            end
          end
        RUBY
      end
    end

    after do
      $app_class_loaded = $app_lib_class_loaded = nil
    end

    specify "Classes in app/lib/ directory are preferred for autoloading" do
      expect(TestApp::TestClass).to be
      expect(TestApp::TestClass.instance_variable_get(:@loaded_from)).to eq ["app/lib"]
      expect($app_lib_class_loaded).to be true
      expect($app_class_loaded).to be nil
    end

    specify "Classes in app/lib/ directory are preferred for auto-registration" do
      expect(TestApp::App["test_class"]).to be
      expect(TestApp::TestClass.instance_variable_get(:@loaded_from)).to eq ["app/lib"]
      expect($app_lib_class_loaded).to be true
      expect($app_class_loaded).to be nil
    end
  end
  # rubocop:enable Style/GlobalVars
end

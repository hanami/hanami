# frozen_string_literal: true

RSpec.describe "Code loading / Loading from slice directory", :app_integration do
  before :context do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/config/not_loadable.rb", <<~'RUBY'
        raise "This file should never be loaded"
      RUBY

      write "slices/main/test_class.rb", <<~'RUBY'
        module Main
          class TestClass
          end
        end
      RUBY

      write "slices/main/action.rb", <<~'RUBY'
        # auto_register: false

        module Main
          class Action < Hanami::Action
          end
        end
      RUBY

      write "slices/main/actions/home/show.rb", <<~'RUBY'
        module Main
          module Actions
            module Home
              class Show < Main::Action
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

  specify "Classes in slice directory are autoloaded with the slice namespace" do
    expect(Main::TestClass).to be
    expect(Main::Action).to be
    expect(Main::Actions::Home::Show).to be
  end

  specify "Files in slice config/ directory are not autoloaded" do
    expect { Main::NotLoadable }.to raise_error NameError
    expect { Main::Config::NotLoadable }.to raise_error NameError
  end

  specify "Classes in slice directory are auto-registered" do
    expect(Main::Slice["test_class"]).to be_an_instance_of Main::TestClass
    expect(Main::Slice["actions.home.show"]).to be_an_instance_of Main::Actions::Home::Show

    # Files with "auto_register: false" magic comments are not auto-registered
    expect(Main::Slice.key?("action")).to be false
  end

  specify "Files in slice config/ directory are not auto-registered" do
    expect(Main::Slice.key?("config.settings")).to be false
  end

  describe "slice lib/ directory" do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/lib/test_class.rb", <<~'RUBY'
          module Main
            class TestClass
            end
          end
        RUBY
      end
    end

    specify "Classes in slice lib/ directory are autoloaded with the slice namespace" do
      expect(Main::TestClass).to be
    end

    specify "Classes in slice lib/ directory are auto-registered" do
      expect(Main::Slice["test_class"]).to be_an_instance_of Main::TestClass
    end

    specify "Classes in slice lib/ directory are not redundantly auto-registered under 'lib' key namespace" do
      expect(Main::Slice.key?("lib.test_class")).to be false
    end
  end

  # rubocop:disable Style/GlobalVars
  describe "same-named class defined in both slice and lib/ directories" do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/test_class.rb", <<~'RUBY'
          $slice_class_loaded = true

          module Main
            class TestClass
              (@loaded_from ||= []) << "slice"
            end
          end
        RUBY

        write "slices/main/lib/test_class.rb", <<~'RUBY'
          $slice_lib_class_loaded = true

          module Main
            class TestClass
              (@loaded_from ||= []) << "slice/lib"
            end
          end
        RUBY
      end
    end

    after do
      $slice_class_loaded = $slice_lib_class_loaded = nil
    end

    specify "Classes in slice lib/ directory are preferred for autoloading" do
      expect(Main::TestClass).to be
      expect(Main::TestClass.instance_variable_get(:@loaded_from)).to eq ["slice/lib"]
      expect($slice_lib_class_loaded).to be true
      expect($slice_class_loaded).to be nil
    end

    specify "Classes in slice lib/ directory are preferred for auto-registration" do
      expect(Main::Slice["test_class"]).to be
      expect(Main::TestClass.instance_variable_get(:@loaded_from)).to eq ["slice/lib"]
      expect($slice_lib_class_loaded).to be true
      expect($slice_class_loaded).to be nil
    end
  end
  # rubocop:enable Style/GlobalVars
end

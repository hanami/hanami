# frozen_string_literal: true

RSpec.describe "App view / Config / Part class", :app_integration do
  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "app view" do
    let(:view_class) { TestApp::View }

    context "no concrete app part class defined" do
      it "generates an app part class and configures it as the view's part_class" do
        expect(view_class.config.part_class).to be TestApp::Views::Part
        expect(view_class.config.part_class.superclass).to be Hanami::View::Part
      end
    end

    context "concrete app part class defined" do
      def before_prepare
        write "app/views/part.rb", <<~RUBY
          # auto_register: false

          module TestApp
            module Views
              class Part < Hanami::View::Part
                def self.concrete?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "configures the app part class as the view's part_class" do
        expect(view_class.config.part_class).to be TestApp::Views::Part
        expect(view_class.config.part_class).to be_concrete
      end
    end
  end

  describe "slice view" do
    let(:view_class) { Main::View }

    def before_prepare
      write "slices/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < TestApp::View
          end
        end
      RUBY
    end

    context "no concrete slice part class defined" do
      it "generates a slice part class, inheriting from the app part class, and configures it as the view's part_class" do
        expect(view_class.config.part_class).to be Main::Views::Part
        expect(view_class.config.part_class.superclass).to be TestApp::Views::Part
      end
    end

    context "concrete slice part class defined" do
      def before_prepare
        super

        write "slices/main/views/part.rb", <<~RUBY
          # auto_register: false

          module Main
            module Views
              class Part < TestApp::Views::Part
                def self.concrete?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "configures the slice part class as the view's part_class" do
        expect(view_class.config.part_class).to be Main::Views::Part
        expect(view_class.config.part_class).to be_concrete
      end
    end

    context "view not inheriting from app view, no concrete part class" do
      def before_prepare
        write "slices/main/view.rb", <<~RUBY
          # auto_register: false

          module Main
            class View < Hanami::View
            end
          end
        RUBY
      end

      it "generates a slice part class, inheriting from the app part class, and configures it as the view's part_class" do
        expect(view_class.config.part_class).to be Main::Views::Part
        expect(view_class.config.part_class.superclass).to be TestApp::Views::Part
      end
    end

    context "no app view class defined" do
      def before_prepare
        FileUtils.rm "app/view.rb"

        write "slices/main/view.rb", <<~RUBY
          # auto_register: false

          module Main
            class View < Hanami::View
            end
          end
        RUBY
      end

      it "generates a slice part class, inheriting from Hanami::View::Part, and configures it as the view's part_class" do
        expect(view_class.config.part_class).to be Main::Views::Part
        expect(view_class.config.part_class.superclass).to be Hanami::View::Part
      end
    end
  end
end

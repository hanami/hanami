# frozen_string_literal: true

RSpec.describe "Container shutdown", :application_integration do
  specify "Application container shuts down components" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/boot/persistence.rb", <<~RUBY
        Hanami.application.register_bootable :persistence do
          init do
            module TestApp
              class Persistence
                attr_reader :connected

                def initialize
                  @connected = true
                end

                def disconnect
                  @connected = false
                end
              end
            end
          end

          start do
            register(:persistence, TestApp::Persistence.new)
          end

          stop do
            container[:persistence].disconnect
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.boot

      persistence = Hanami.application[:persistence]

      expect(persistence).to be_kind_of(TestApp::Persistence)
      expect(persistence.connected).to be(true)

      Hanami.shutdown

      expect(persistence.connected).to be(false)
    end
  end
end

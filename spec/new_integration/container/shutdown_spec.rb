# frozen_string_literal: true

RSpec.describe "App shutdown", :app_integration do
  specify "App shutdown stops providers in both the app and slices" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        # frozen_string_literal: true

        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/connection.rb", <<~RUBY
        # frozen_string_literal: true

        Hanami.app.register_provider :connection do
          prepare do
            module TestApp
              class Connection
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
            register("connection", TestApp::Connection.new)
          end

          stop do
            container["connection"].disconnect
          end
        end
      RUBY

      write "slices/main/config/providers/connection.rb", <<~RUBY
        # frozen_string_literal: true

        Main::Slice.register_provider :connection do
          prepare do
            module Main
              class Connection
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
            register "connection", Main::Connection.new
          end

          stop do
            container["connection"].disconnect
          end
        end
      RUBY

      require "hanami/boot"

      app_connection = Hanami.app["connection"]
      slice_connection = Main::Slice["connection"]

      expect(app_connection.connected).to be true
      expect(slice_connection.connected).to be true

      Hanami.shutdown

      expect(app_connection.connected).to be false
      expect(slice_connection.connected).to be false
    end
  end
end

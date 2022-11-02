# frozen_string_literal: true

RSpec.describe "Container / Provider lifecycle", :app_integration do
  let!(:slice) {
    module TestApp
      class App < Hanami::App
        register_provider :connection do
          prepare do
            module ::TestApp
              class Connection
                def initialize
                  @connected = true
                end

                def disconnect
                  @connected = false
                end

                def connected?
                  @connected
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
      end
    end

    TestApp::App
  }

  before do
    require "hanami/setup"
  end

  specify "individual providers can be prepared, started and stopped" do
    expect { TestApp::Connection }.to raise_error NameError

    slice.prepare :connection

    expect(TestApp::Connection).to be
    expect(slice.container.registered?("connection")).to be false

    slice.start :connection

    expect(slice.container.registered?("connection")).to be true
    expect(slice["connection"]).to be_connected

    slice.stop :connection

    expect(slice["connection"]).not_to be_connected
  end
end

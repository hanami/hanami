RSpec.describe "Components: model", type: :cli do
  context "with hanami-model" do
    it "resolves model" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('model')

        expect(Hanami::Components['model']).to     be(true)
        expect(Hanami::Components['model.sql']).to be(true)
        expect(Hanami::Model.configuration.logger).to eq(Hanami.logger)
      end
    end

    it "disconnects database connections on reboot" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")

        # Simulate previous connection
        Hanami::Components.resolve('model.configuration')
        Hanami::Components.resolve('model.sql')
        Hanami::Model.load!

        #
        Hanami::Model.configuration.connection.test_connection
        # Current connections count is 1

        #
        Hanami::Components.resolve('model')
        # Current connections count is 0

        expect(Hanami::Components['model']).to     be(true)
        expect(Hanami::Components['model.sql']).to be(true)
        expect(Hanami::Model.configuration.logger).to eq(Hanami.logger)

        # This is tight coupled to Sequel
        #
        # When `.disconnect` is invoked, it returns a collection of disconnected
        # connections. Here we want to assert that `.disconnect` was invoked as
        # part of the boot process.
        #
        # Invoking disconnect again **here in the test** should return an empty
        # collection, because we haven't tried to connect to the database again.
        expect(Hanami::Model.disconnect).to be_empty
      end
    end
  end
end

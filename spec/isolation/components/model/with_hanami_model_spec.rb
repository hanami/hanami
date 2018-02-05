RSpec.describe "Components: model", type: :integration do
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
  end
end

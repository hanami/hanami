RSpec.describe "Components: model.sql", type: :integration do
  context "with hanami-model" do
    it "resolves model configuration" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('model.sql')

        expect(Hanami::Components['model.configuration']).to_not be(nil)
        expect(Hanami::Components['model.sql']).to               be(true)
      end
    end
  end
end

RSpec.describe "Components: model.configuration", type: :cli do
  context "with hanami-model" do
    it "resolves model configuration" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('model.configuration')

        expect(Hanami::Components['model.configuration']).to be_kind_of(Hanami::Model::Configuration)
      end
    end
  end
end

RSpec.describe "Components: model", type: :cli do
  context "with hanami-model" do
    it "resolves model" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('model.bundled')

        expect(Hanami::Components['model.bundled']).to be(true)
      end
    end
  end
end

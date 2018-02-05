RSpec.describe "Components: app", type: :integration do
  it "loads a single Hanami application within the project" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(Hanami::Components['web.configuration']).to_not be_nil
      expect(Hanami::Components['web']).to                   be(true)
    end
  end
end

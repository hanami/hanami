RSpec.describe "Components: routes.inspector", type: :integration do
  it "loads project routes inspector" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('routes.inspector')

      expect(Hanami::Components['routes.inspector']).to be_kind_of(Hanami::Components::RoutesInspector)
    end
  end
end

RSpec.describe "Components: app.controller", type: :cli do
  it "loads a single Hanami application's hanami-controller configuration" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(Hanami::Components['web.controller']).to be_kind_of(Hanami::Controller::Configuration)
    end
  end
end

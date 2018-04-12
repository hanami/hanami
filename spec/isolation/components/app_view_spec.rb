RSpec.describe "Components: app.view", type: :integration do
  it "loads a single Hanami application's hanami-view configuration" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(Hanami::Components['web.view']).to be_kind_of(Hanami::View::Configuration)
      expect(defined?(Web::View)).to            eq("constant")
    end
  end
end

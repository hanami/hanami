RSpec.describe "Components: app.frameworks", type: :integration do
  it "loads a single Hanami application's frameworks" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(defined?(Web::Action)).to eq("constant")
      expect(defined?(Web::View)).to   eq("constant")
      expect(defined?(Web::Assets)).to eq("constant")

      expect(Web.routes).to be_kind_of(Hanami::Routes)
    end
  end
end

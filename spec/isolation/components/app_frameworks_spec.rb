RSpec.describe "Components: app.frameworks", type: :cli do
  it "loads a single Hanami application's frameworks" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('apps') # the component under test can't be resolved directly

      expect(defined?(Web::View)).to   eq("constant")
      expect(defined?(Web::Assets)).to eq("constant")

      # FIXME: this MUST be restored
      # expect(Web.routes).to be_kind_of(Hanami::Router)
    end
  end
end

RSpec.describe "Components: finalizers", type: :cli do
  it "finalizes project" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('finalizers')

      expect(Hanami::Components['finalizers']).to be(true)
    end
  end
end

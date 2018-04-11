RSpec.describe "Hanami.root", type: :integration do
  it "returns project root" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      expect(Hanami.root).to eq(Pathname.new(Dir.pwd))
    end
  end
end

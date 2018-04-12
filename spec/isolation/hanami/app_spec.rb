RSpec.describe "Hanami.app", type: :integration do
  it "returns app instance" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      expect(Hanami.app).to be_kind_of(Hanami::App)
    end
  end
end

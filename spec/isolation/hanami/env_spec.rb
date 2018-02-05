RSpec.describe "Hanami.env", type: :integration do
  it "returns current env" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      expect(Hanami.env).to eq("development")
    end
  end
end

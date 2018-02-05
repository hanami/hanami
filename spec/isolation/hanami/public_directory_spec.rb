RSpec.describe "Hanami.public_directory", type: :integration do
  it "returns project public directory" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      expect(Hanami.public_directory).to eq(Pathname.new(Dir.pwd).join("public"))
    end
  end
end

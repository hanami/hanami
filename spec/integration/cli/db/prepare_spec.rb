RSpec.describe "hanami db", type: :cli do
  describe "prepare" do
    it "prepares database" do
      with_project do
        versions = generate_migrations

        hanami "db prepare"
        hanami "db version"

        expect(out).to include(versions.last.to_s)
      end
    end
  end
end

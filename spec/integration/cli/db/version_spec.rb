RSpec.describe "hanami db", type: :cli do
  describe "version" do
    it "prints database version" do
      with_project do
        versions = generate_migrations

        hanami "db create"
        hanami "db migrate"
        hanami "db version"

        expect(out).to include(versions.last.to_s)
      end
    end
  end
end

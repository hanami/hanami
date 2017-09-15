require "pathname"

RSpec.describe "CLI plugins", type: :cli do
  it "includes its commands in CLI output" do
    with_project("bookshelf", gems: { "hanami-plugin" => { groups: [:plugins], path: Pathname.new(__dir__).join("..", "..", "..", "spec", "support", "fixtures", "hanami-plugin").realpath.to_s } }) do
      bundle_exec "hanami"
      expect(out).to include("hanami plugin [SUBCOMMAND]")
    end
  end
end

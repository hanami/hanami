require "pathname"

RSpec.describe "CLI plugins", type: :cli do
  it "includes its commands in CLI output" do
    with_project do
      bundle_exec "hanami"
      expect(out).to include("hanami plugin [SUBCOMMAND]")
    end
  end

  it "executes command from plugin" do
    with_project do
      bundle_exec "hanami plugin version"
      expect(out).to include("v0.1.0")
    end
  end

  private

  def with_project
    super("bookshelf", gems: { "hanami-plugin" => { groups: [:plugins], path: Pathname.new(__dir__).join("..", "..", "..", "spec", "support", "fixtures", "hanami-plugin").realpath.to_s } }) do
      yield
    end
  end
end

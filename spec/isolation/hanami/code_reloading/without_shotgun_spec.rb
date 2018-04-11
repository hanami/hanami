RSpec.describe "Hanami.code_reloading?", type: :integration do
  context "without shotgun" do
    it "returns false" do
      with_project("bookshelf", exclude_gems: ["shotgun"]) do
        write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami.boot
puts "code reloading: \#{Hanami.code_reloading?}"
EOF
        bundle_exec "ruby script/components"

        expect(out).to include("code reloading: false")
      end
    end
  end
end

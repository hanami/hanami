RSpec.describe "Components: model.bundled", type: :integration do
  context "without hanami-model" do
    it "is nil" do
      project_without_hanami_model do
        write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami::Components.resolve('model.bundled')
puts Hanami::Components['model.bundled'].class
EOF

        bundle_exec "ruby script/components"
        expect(out).to include("NilClass")
      end
    end
  end
end

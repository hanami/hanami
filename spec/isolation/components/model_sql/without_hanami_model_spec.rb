RSpec.describe "Components: model.sql", type: :cli do
  context "without hanami-model" do
    it "is nil" do
      project_without_hanami_model do
        write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami::Components.resolve('model.sql')
puts Hanami::Components['model.configuration'].class
EOF

        bundle_exec "ruby script/components"
        expect(out).to include("NilClass")
      end
    end
  end
end

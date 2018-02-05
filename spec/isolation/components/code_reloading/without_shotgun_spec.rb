RSpec.describe "Components: code_reloading", type: :integration do
  context "without shotgun" do
    context "with code reloading disabled" do
      it "is false" do
        with_project("code_reloading", exclude_gems: ['shotgun']) do
          write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami::Components.resolved('environment', Hanami::Environment.new(code_reloading: false))
Hanami::Components.resolve('code_reloading')
puts Hanami::Components['code_reloading'].class
EOF

          RSpec::Support::Bundler.with_clean_env do
            bundle_exec "ruby script/components"
          end

          expect(out).to include("FalseClass")
        end
      end
    end
  end
end

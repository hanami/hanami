RSpec.describe "Components: logger", type: :integration do
  it "accepts arbitrary arguments" do
    with_project do
      count = 5
      replace 'config/environment.rb', 'logger ', "logger #{count}, 128, stream: 'log/development.log'"

      write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami.boot
Hanami::Components.resolve('logger')

10.times do
  Hanami.logger.debug 'hello'
end
EOF

      bundle_exec "ruby script/components"

      logs = Hanami::Utils::FileList['log/development.log*']
      expect(logs.count).to eq(count)
    end
  end
end

RSpec.describe "Components: logger", type: :cli do
  let(:project_name) { "bookshelf" }

  it "setups Hanami project's logger" do
    with_project do
      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('logger')

      expect(Hanami.logger).to be_kind_of(Hanami::Logger)
      expect(Hanami.logger.application_name).to eq(project_name)
      expect(Hanami.logger.level).to            eq(::Logger::DEBUG)
    end
  end

  it "accepts arbitrary arguments" do
    with_project do
      FileUtils.mkpath('log')
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

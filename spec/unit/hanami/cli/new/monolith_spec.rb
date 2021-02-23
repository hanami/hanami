# frozen_string_literal: true

require "hanami/cli/new"

RSpec.describe Hanami::CLI::New do
  context "architecture: monolith" do
    subject { described_class.new(out: stdout, fs: fs, inflector: inflector) }

    let(:stdout) { StringIO.new }
    let(:fs) { RSpec::Support::FileSystem.new }
    let(:inflector) { Dry::Inflector.new }
    let(:app) { "bookshelf" }
    let(:architecture) { "monolith" }

    it "generates an application" do
      subject.call(app: app, architecture: architecture)

      stdout.rewind
      expect(stdout.read.chomp).to eq("generating #{app}")

      expect(fs.directory?(app)).to be(true)

      fs.chdir(app) do
        # .env
        env = <<~EXPECTED
        EXPECTED
        expect(fs.read(".env")).to eq(env)

        # README.md
        readme = <<~EXPECTED
          # #{inflector.classify(app)}
        EXPECTED
        expect(fs.read("README.md")).to eq(readme)

        # Gemfile
        hanami_version = Hanami::Version.gem_requirement
        gemfile = <<~EXPECTED
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake"

          gem "hanami-router", "#{hanami_version}"
          gem "hanami-controller", "#{hanami_version}"
          gem "hanami-validations", "#{hanami_version}"
          gem "hanami-view", "#{hanami_version}"
          gem "hanami", "#{hanami_version}"

          gem "puma"
        EXPECTED
        expect(fs.read("Gemfile")).to eq(gemfile)

        # Rakefile
        rakefile = <<~EXPECTED
          # frozen_string_literal: true

          require "rake"
          require "hanami/rake_tasks"

          begin
            require "rspec/core/rake_task"
            RSpec::Core::RakeTask.new(:spec)
            task default: :spec
          rescue LoadError
          end
        EXPECTED
        expect(fs.read("Rakefile")).to eq(rakefile)

        # config.ru
        config_ru = <<~EXPECTED
          # frozen_string_literal: true

          require_relative "./config/application"

          run Hanami.app
        EXPECTED
        expect(fs.read("config.ru")).to eq(config_ru)

        # config/application.rb
        application = <<~EXPECTED
          # frozen_string_literal: true

          require "hanami"

          module Bookshelf
            class Application < Hanami::Application
            end
          end
        EXPECTED
        expect(fs.read("config/application.rb")).to eq(application)

        # config/settings.rb
        settings = <<~EXPECTED
          # frozen_string_literal: true

          require "#{app}/types"

          Hanami.application.settings do
          end
        EXPECTED
        expect(fs.read("config/settings.rb")).to eq(settings)

        # config/routes.rb
        routes = <<~EXPECTED
          # frozen_string_literal: true

          Hanami.application.routes do
            slice :main, at: "/" do
            end
          end
        EXPECTED
        expect(fs.read("config/routes.rb")).to eq(routes)

        # lib/bookshelf/types.rb
        types = <<~EXPECTED
          # auto_register: false
          # frozen_string_literal: true

          require "dry/types"

          module #{inflector.classify(app)}
            module Types
              include Dry.Types
            end
          end
        EXPECTED
        expect(fs.read("lib/#{app}/types.rb")).to eq(types)
      end
    end
  end
end

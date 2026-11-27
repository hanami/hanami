# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe Hanami::GemVersionCheck do
  subject(:call) { described_class.(env:, specs:, hanami_version:) }

  def spec_for(name, version)
    Gem::Specification.new do |s|
      s.name = name
      s.version = version
    end
  end

  let(:env) { {} }
  let(:hanami_version) { "3.1.2" }

  context "all first-party gems on the same major.minor" do
    let(:specs) {
      {
        "hanami-view" => spec_for("hanami-view", "3.1.0"),
        "hanami-router" => spec_for("hanami-router", "3.1.5"),
        "hanami-action" => spec_for("hanami-action", "3.1.0.beta1")
      }
    }

    it "does not raise" do
      expect { call }.not_to raise_error
    end
  end

  context "a first-party gem on a different minor version" do
    let(:specs) {
      {
        "hanami-view" => spec_for("hanami-view", "3.0.2"),
        "hanami-db" => spec_for("hanami-db", "3.1.0")
      }
    }

    it "raises an error naming the mismatched gems" do
      expect { call }.to raise_error(Hanami::GemVersionError) { |error|
        expect(error.message).to start_with(
          "hanami is 3.1.2, but these gems are not on 3.1.x:\n\n  hanami-view 3.0.2\n"
        )
        expect(error.message).not_to include "hanami-db"
        expect(error.message).to include "HANAMI_SKIP_GEM_VERSION_CHECK=1"
      }
    end

    context "HANAMI_SKIP_GEM_VERSION_CHECK set" do
      let(:env) { {"HANAMI_SKIP_GEM_VERSION_CHECK" => "1"} }

      it "does not raise" do
        expect { call }.not_to raise_error
      end
    end
  end

  context "a first-party gem on a different major version" do
    let(:specs) { {"hanami-utils" => spec_for("hanami-utils", "2.3.0")} }

    it "raises an error naming the gem" do
      expect { call }.to raise_error(Hanami::GemVersionError, /hanami-utils 2\.3\.0/)
    end
  end

  context "a hanami prerelease" do
    let(:hanami_version) { "3.1.0.rc1" }
    let(:specs) { {"hanami-view" => spec_for("hanami-view", "3.1.0")} }

    it "does not raise" do
      expect { call }.not_to raise_error
    end
  end

  context "a third-party gem with a hanami- prefix" do
    let(:specs) { {"hanami-something-else" => spec_for("hanami-something-else", "0.1.0")} }

    it "does not raise" do
      expect { call }.not_to raise_error
    end
  end

  describe ".requirements_for" do
    it "returns requirements for the same major.minor as hanami, allowing prereleases" do
      requirements = described_class.requirements_for("hanami-router", hanami_version: "3.1.0.rc1")

      expect(requirements).to eq [">= 3.1.0.a", "< 3.2.a"]

      requirement = Gem::Requirement.new(*requirements)
      expect(requirement).to be_satisfied_by Gem::Version.new("3.1.0.rc1")
      expect(requirement).to be_satisfied_by Gem::Version.new("3.1.4")
      expect(requirement).not_to be_satisfied_by Gem::Version.new("3.0.1")
      expect(requirement).not_to be_satisfied_by Gem::Version.new("3.2.0.beta1")
    end

    it "returns no requirements for other gems" do
      expect(described_class.requirements_for("dry-operation", hanami_version: "3.1.0")).to eq []
    end
  end

  describe "on require \"hanami\"" do
    # Runs in a separate process, since hanami is already loaded here
    def require_hanami(env = {})
      script = <<~RUBY
        # A gem not in this bundle, so nothing tries to activate its real version
        Gem.loaded_specs["hanami-minitest"] = Gem::Specification.new { |s|
          s.name = "hanami-minitest"
          s.version = "2.3.0"
        }
        require "hanami"
      RUBY

      env = {"BUNDLE_GEMFILE" => Bundler.default_gemfile.to_s}.merge(env)
      lib = File.expand_path("../../../lib", __dir__)

      Open3.capture3(env, RbConfig.ruby, "-rbundler/setup", "-I", lib, "-e", script)
    end

    it "fails on a mismatch" do
      _, err, status = require_hanami

      expect(status).not_to be_success
      expect(err).to include "Hanami::GemVersionError"
      expect(err).to include "hanami-minitest 2.3.0"
    end

    it "loads when HANAMI_SKIP_GEM_VERSION_CHECK is set" do
      _, err, status = require_hanami("HANAMI_SKIP_GEM_VERSION_CHECK" => "1")

      expect(status).to be_success, err
    end
  end
end

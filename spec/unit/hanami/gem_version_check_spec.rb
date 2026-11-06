# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe Hanami::GemVersionCheck do
  def spec_for(name, version)
    Gem::Specification.new do |s|
      s.name = name
      s.version = version
    end
  end

  let(:hanami_version) { "3.1.2" }

  describe ".mismatches" do
    subject(:mismatches) { described_class.mismatches(specs:, hanami_version:) }

    context "all first-party gems on the same major.minor" do
      let(:specs) {
        {
          "hanami-view" => spec_for("hanami-view", "3.1.0"),
          "hanami-router" => spec_for("hanami-router", "3.1.5"),
          "hanami-action" => spec_for("hanami-action", "3.1.0.beta1")
        }
      }

      it { is_expected.to eq({}) }
    end

    context "a first-party gem on a different minor version" do
      let(:specs) {
        {
          "hanami-view" => spec_for("hanami-view", "3.0.2"),
          "hanami-router" => spec_for("hanami-router", "3.1.0")
        }
      }

      it { is_expected.to eq("hanami-view" => Gem::Version.new("3.0.2")) }
    end

    context "a first-party gem on a different major version" do
      let(:specs) { {"hanami-utils" => spec_for("hanami-utils", "2.3.0")} }

      it { is_expected.to eq("hanami-utils" => Gem::Version.new("2.3.0")) }
    end

    context "a hanami prerelease" do
      let(:hanami_version) { "3.1.0.rc1" }
      let(:specs) { {"hanami-view" => spec_for("hanami-view", "3.1.0")} }

      it { is_expected.to eq({}) }
    end

    context "a third-party gem with a hanami- prefix" do
      let(:specs) { {"hanami-something-else" => spec_for("hanami-something-else", "0.1.0")} }

      it { is_expected.to eq({}) }
    end
  end

  describe ".call" do
    subject(:call) { described_class.(env:, specs:, hanami_version:, stderr:) }

    let(:env) { {} }
    let(:stderr) { StringIO.new }

    let(:specs) {
      {
        "hanami-view" => spec_for("hanami-view", "3.0.2"),
        "hanami-db" => spec_for("hanami-db", "3.1.0")
      }
    }

    shared_examples "warns" do
      it "prints a warning naming the mismatched gems" do
        call

        expect(stderr.string).to match(
          /!{80}\nHanami gem version mismatch: hanami is 3\.1\.2, but these gems are not on 3\.1\.x:\n\n  hanami-view  3\.0\.2\n/
        )
        expect(stderr.string).to include "HANAMI_GEM_VERSION_MISMATCH=ignore"
      end

      it "does not name gems on the matching version" do
        call

        expect(stderr.string).not_to include "hanami-db"
      end
    end

    context "HANAMI_GEM_VERSION_MISMATCH unset" do
      include_examples "warns"
    end

    context "HANAMI_GEM_VERSION_MISMATCH=warn" do
      let(:env) { {"HANAMI_GEM_VERSION_MISMATCH" => "warn"} }

      include_examples "warns"
    end

    context "HANAMI_GEM_VERSION_MISMATCH=raise" do
      let(:env) { {"HANAMI_GEM_VERSION_MISMATCH" => "raise"} }

      it "raises an error naming the mismatched gems" do
        expect { call }.to raise_error(Hanami::GemVersionMismatchError, /hanami-view  3\.0\.2/)
      end
    end

    context "HANAMI_GEM_VERSION_MISMATCH=ignore" do
      let(:env) { {"HANAMI_GEM_VERSION_MISMATCH" => "ignore"} }

      it "does nothing" do
        call

        expect(stderr.string).to be_empty
      end
    end

    context "HANAMI_GEM_VERSION_MISMATCH is unknown" do
      let(:env) { {"HANAMI_GEM_VERSION_MISMATCH" => "explode"} }

      it "raises an error" do
        expect { call }.to raise_error(ArgumentError, /must be one of warn, raise, ignore, got "explode"/)
      end
    end

    context "no mismatches" do
      let(:env) { {"HANAMI_GEM_VERSION_MISMATCH" => "raise"} }
      let(:specs) { {"hanami-view" => spec_for("hanami-view", "3.1.0")} }

      it "does nothing" do
        expect { call }.not_to raise_error
        expect(stderr.string).to be_empty
      end
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

      Open3.capture3(env, RbConfig.ruby, "-W0", "-rbundler/setup", "-I", lib, "-e", script)
    end

    it "warns, even with warnings disabled" do
      _, err, status = require_hanami

      expect(status).to be_success, err
      expect(err).to include "hanami-minitest  2.3.0"
    end

    it "fails when HANAMI_GEM_VERSION_MISMATCH=raise" do
      _, err, status = require_hanami("HANAMI_GEM_VERSION_MISMATCH" => "raise")

      expect(status).not_to be_success
      expect(err).to include "Hanami::GemVersionMismatchError"
    end
  end
end

# frozen_string_literal: true

require "hanami/app_detector"
require "hanami/devtools/integration/with_tmp_directory"
require "hanami/devtools/integration/files"

RSpec.describe Hanami::AppDetector do
  include RSpec::Support::WithTmpDirectory
  include RSpec::Support::Files

  describe "#call" do
    let(:dir) { Dir.mktmpdir }

    context "when app.rb exists in the current directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "app.rb"

          expect(subject.()).to match(%r{^/.*app.rb$})
        end
      end
    end

    context "when config/app.rb exists in the current directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "config/app.rb"

          expect(subject.()).to match(%r{^/.*config/app.rb$})
        end
      end
    end

    context "when app.rb exists in the parent directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "app.rb"
          write "lib/.keep"

          Dir.chdir("lib") do
            expect(subject.()).to match(%r{^/.*app.rb$})
          end
        end
      end
    end

    context "when config/app.rb exists in the parent directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "config/app.rb"
          write "lib/.keep"

          Dir.chdir("lib") do
            expect(subject.()).to match(%r{^/.*config/app.rb$})
          end
        end
      end
    end

    context "when an application file exists above the parent directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "app.rb"
          write "lib/tasks/.keep"

          Dir.chdir("lib/tasks") do
            expect(subject.()).to match(%r{^/.*app.rb$})
          end
        end
      end

    end

    context "when both app.rb and config/app.rb exist at the same level" do
      it "returns the absolute path for config/app.rb" do
        with_tmp_directory(dir) do
          write "app.rb"
          write "config/app.rb"

          result = subject.()
          expect(result).to match(%r{^/.*/config/app.rb$})
        end
      end
    end

    context "when there's no application file in the current directory or above" do
      it "returns nil" do
        with_tmp_directory(dir) do
          expect(subject.()).to be(nil)
        end
      end
    end

    context "when there's a directory with same name as the application file" do
      it "returns nil" do
        with_tmp_directory(dir) do
          write "app.rb/.keep"

          expect(subject.()).to be(nil)
        end
      end
    end
  end
end

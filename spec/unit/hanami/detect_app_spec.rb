# frozen_string_literal: true

require "hanami/detect_app"
require "hanami/devtools/integration/with_tmp_directory"
require "hanami/devtools/integration/files"

RSpec.describe Hanami::DetectApp do
  include RSpec::Support::WithTmpDirectory
  include RSpec::Support::Files

  subject(:detect_app) { described_class }

  describe "#call" do
    let(:dir) { Dir.mktmpdir }

    context "config/app.rb exists in current directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "config/app.rb"

          expect(subject.()).to match(%r{^/.*/config/app.rb$})
        end
      end
    end

    context "config/app.rb exists in a parent directory" do
      it "returns its absolute path" do
        with_tmp_directory(dir) do
          write "config/app.rb"
          write "lib/foo/bar/.keep"

          Dir.chdir("lib/foo/bar") do
            expect(subject.()).to match(%r{^/.*/config/app.rb$})
          end
        end
      end
    end

    context "no app file in any directory" do
      it "returns nil" do
        with_tmp_directory(dir) do
          expect(subject.()).to be(nil)
        end
      end
    end

    context "directory exists with same name as the app file" do
      it "returns nil" do
        with_tmp_directory(dir) do
          write "config/app.rb/.keep"

          expect(subject.()).to be(nil)
        end
      end
    end
  end
end

# frozen_string_literal: true

require "hanami/settings/yaml_file_store"
require "tmpdir"

RSpec.describe Hanami::Settings::YamlFileStore do
  subject(:store) { described_class.new(path) }

  let(:root) { Pathname(Dir.mktmpdir) }
  let(:path) { root.join("settings.yml") }

  def write(contents)
    File.write(path, contents)
  end

  after { FileUtils.remove_entry(root) }

  describe "#initialize" do
    it "raises when given neither a path nor a block" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "raises when given both a path and a block" do
      expect { described_class.new(path) { path } }.to raise_error(ArgumentError)
    end
  end

  describe "#path" do
    it "returns the given path" do
      expect(store.path).to eq path
    end

    it "resolves the path from the given block" do
      resolved = 0
      store = described_class.new {
        resolved += 1
        path
      }

      expect(store.path).to eq path
      expect(store.path).to eq path
      expect(resolved).to eq 1
    end

    it "does not resolve the block until the path is needed" do
      expect { described_class.new { raise "should not be called" } }.not_to raise_error
    end
  end

  describe "#fetch" do
    it "fetches values by name" do
      write("database_url: postgres://localhost/database\n")

      expect(store.fetch(:database_url)).to eq "postgres://localhost/database"
      expect(store.fetch("database_url")).to eq "postgres://localhost/database"
    end

    it "returns nested values as hashes with symbol keys" do
      write(<<~YAML)
        redis:
          url: redis://localhost
      YAML

      expect(store.fetch(:redis)).to eq(url: "redis://localhost")
    end

    it "evaluates the file as ERB before parsing it as YAML" do
      write("database_url: <%= 'postgres://localhost/database' %>\n")

      expect(store.fetch(:database_url)).to eq "postgres://localhost/database"
    end

    it "supports YAML aliases" do
      write(<<~YAML)
        defaults: &defaults
          url: redis://localhost
        redis:
          <<: *defaults
      YAML

      expect(store.fetch(:redis)).to eq(url: "redis://localhost")
    end

    it "supports dates and times" do
      write("expires_at: 2026-01-01\n")

      expect(store.fetch(:expires_at)).to eq Date.new(2026, 1, 1)
    end

    it "returns the default value when the file does not have the key" do
      write("database_url: postgres://localhost/database\n")

      expect(store.fetch(:missing, "default")).to eq "default"
    end

    it "yields to the block when the file does not have the key and no default is given" do
      write("database_url: postgres://localhost/database\n")

      expect(store.fetch(:missing) { "from_block" }).to eq "from_block" # rubocop:disable Style/RedundantFetchBlock
    end

    it "raises KeyError when the file does not have the key and no default is given" do
      write("database_url: postgres://localhost/database\n")

      expect { store.fetch(:missing) }.to raise_error(KeyError)
    end

    it "returns a nil value given for a key" do
      write("database_url:\n")

      expect(store.fetch(:database_url, "default")).to be nil
    end

    it "reads the file only once" do
      write("database_url: postgres://localhost/database\n")

      expect(store.fetch(:database_url)).to eq "postgres://localhost/database"

      write("database_url: postgres://localhost/other\n")

      expect(store.fetch(:database_url)).to eq "postgres://localhost/database"
    end

    context "file does not exist" do
      it "behaves as an empty store" do
        expect(store.fetch(:database_url, "default")).to eq "default"
        expect { store.fetch(:database_url) }.to raise_error(KeyError)
      end
    end

    context "empty file" do
      it "behaves as an empty store" do
        write("# just a comment\n")

        expect(store.fetch(:database_url, "default")).to eq "default"
      end
    end

    context "file does not contain a mapping" do
      it "raises an error naming the file" do
        write("- one\n- two\n")

        expect { store.fetch(:database_url) }
          .to raise_error(Hanami::Error, /#{Regexp.escape(path.to_s)}.*Array/)
      end
    end
  end
end

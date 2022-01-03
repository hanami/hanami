# frozen_string_literal: true

require "hanami/configuration"

RSpec.describe Hanami::Configuration, "#source_dirs" do
  subject(:source_dirs) { described_class.new(env: :development).source_dirs }

  describe "#component_dirs" do
    it "defaults to 'lib, actions, repositories, views'" do
      expect(source_dirs.component_dirs.paths).to eq %w[lib actions repositories views]
    end

    it "can have configuration set that applies to all directories" do
      auto_register_proc = -> * { true }
      expect { source_dirs.component_dirs.auto_register = auto_register_proc }
        .to change { source_dirs.component_dirs.dir("lib").auto_register }
        .to(auto_register_proc)
    end

    it "can have extra configuration applied to specific default directories" do
      auto_register_proc = -> * { true }
      expect { source_dirs.component_dirs.dir("lib").auto_register = auto_register_proc }
        .to change { source_dirs.component_dirs.dir("lib").auto_register }
        .to(auto_register_proc)
    end

    it "can have default directories removed" do
      expect { source_dirs.component_dirs.delete("views") }
        .to change { source_dirs.component_dirs.paths }
        .from(%w[lib actions repositories views])
        .to(%w[lib actions repositories])
    end
  end

  describe "#autoload_paths" do
    it "defaults to 'entities'" do
      expect(source_dirs.autoload_paths).to eq %w[entities]
    end

    it "can have new paths added" do
      expect { source_dirs.autoload_paths << "structs" }
        .to change { source_dirs.autoload_paths }
        .to(%w[entities structs])
    end

    it "can have multiple new paths added" do
      expect { source_dirs.autoload_paths += %w[structs values] }
        .to change { source_dirs.autoload_paths }
        .to(%w[entities structs values])
    end

    it "can have paths deleted" do
      expect { source_dirs.autoload_paths.delete("entities") }
        .to change { source_dirs.autoload_paths }
        .to([])
    end
  end
end

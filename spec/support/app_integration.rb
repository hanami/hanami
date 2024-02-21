# frozen_string_literal: true

require "hanami/devtools/integration/files"
require "hanami/devtools/integration/with_tmp_directory"
require "json"
require "tmpdir"
require "zeitwerk"

module RSpec
  module Support
    module WithTmpDirectory
      private

      def make_tmp_directory
        Pathname(Dir.mktmpdir).tap do |dir|
          (@made_tmp_dirs ||= []) << dir
        end
      end
    end

    module App
      def self.included(base)
        super

        base.class_eval do
          let!(:node_modules_path) { File.join(Dir.pwd, "node_modules") }
        end
      end

      private

      # TODO: make slice-aware
      def stub_assets(*assets)
        manifest_hash = assets.each_with_object({}) { |source_path, hsh|
          hsh[source_path] = {url: File.join("/assets", source_path)}
        }

        write "public/assets/assets.json", JSON.generate(manifest_hash)

        # An assets dir is required to load the assets provider
        write "app/assets/.keep", ""
      end

      def compile_assets!
        link_node_modules
        generate_assets_config

        require "hanami/cli/command"
        require "hanami/cli/commands/app/command"
        require "hanami/cli/commands/app/assets/compile"
        assets_compile = Hanami::CLI::Commands::App::Assets::Compile.new(
          config: Hanami.app.config.assets,
          out: File.new(File::NULL, "w"),
          err: File.new(File::NULL, "w"),
        )

        with_directory(Hanami.app.root) { assets_compile.call }
      end

      def link_node_modules
        root = Hanami.app.root

        return if File.exist?(File.join(root, "node_modules", "hanami-assets", "dist", "hanami-assets.js"))

        FileUtils.ln_s(node_modules_path, root)
      rescue Errno::EEXIST # rubocop:disable Lint/SuppressedException
      end

      def generate_assets_config
        root = Hanami.app.root

        with_directory(root) do
          write("config/assets.js", <<~JS) unless root.join("config", "assets.js").exist?
            import * as assets from "hanami-assets";
            await assets.run();
          JS

          write("package.json", <<~JSON) unless root.join("package.json").exist?
            {
              "type": "module"
            }
          JSON
        end
      end
    end
  end
end

RSpec.shared_context "App integration" do
  let(:app_modules) { %i[TestApp Admin Main Search] }
end

def autoloaders_teardown!
  ObjectSpace.each_object(Zeitwerk::Loader) do |loader|
    loader.unregister if loader.dirs.any? { |dir|
      dir.include?("/spec/") || dir.include?(Dir.tmpdir) ||
        dir.include?("/slices/") || dir.include?("/app")
    }
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, :app_integration
  config.include RSpec::Support::WithTmpDirectory, :app_integration
  config.include RSpec::Support::App, :app_integration
  config.include_context "App integration", :app_integration

  config.before :each, :app_integration do
    # Conditionally assign these in case they have been assigned earlier for specific
    # example groups (e.g. container/prepare_container_spec.rb)
    @load_paths ||= $LOAD_PATH.dup
    @loaded_features ||= $LOADED_FEATURES.dup
  end

  config.after :each, :app_integration do
    autoloaders_teardown!

    Hanami.instance_variable_set(:@_bundled, {})
    Hanami.remove_instance_variable(:@_app) if Hanami.instance_variable_defined?(:@_app)

    $LOAD_PATH.replace(@load_paths)

    # Remove example-specific LOADED_FEATURES added when running each example
    new_features_to_keep = ($LOADED_FEATURES - @loaded_features).tap { |feats|
      feats.delete_if do |path|
        path =~ %r{hanami/(setup|prepare|boot|application/container/providers)} ||
          path.include?(SPEC_ROOT.to_s) ||
          path.include?(Dir.tmpdir)
      end
    }
    $LOADED_FEATURES.replace(@loaded_features + new_features_to_keep)

    app_modules.each do |app_module_name|
      next unless Object.const_defined?(app_module_name)

      Object.const_get(app_module_name).tap do |mod|
        mod.constants.each do |name|
          mod.send(:remove_const, name)
        end
      end

      Object.send(:remove_const, app_module_name)
    end
  end

  config.after :all do
    if instance_variable_defined?(:@made_tmp_dirs)
      Array(@made_tmp_dirs).each do |dir|
        FileUtils.remove_entry dir
      end
    end
  end
end

# frozen_string_literal: true

require "hanami/devtools/integration/files"
require "hanami/devtools/integration/with_tmp_directory"
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
  end
end

RSpec.shared_context "Application integration" do
  let(:application_modules) { %i[TestApp Admin Main Search] }
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, :app_integration
  config.include RSpec::Support::WithTmpDirectory, :app_integration
  config.include_context "Application integration", :app_integration

  config.before :each, :app_integration do
    # Conditionally assign these in case they have been assigned earlier for specific
    # example groups (e.g. container/prepare_container_spec.rb)
    @load_paths ||= $LOAD_PATH.dup
    @loaded_features ||= $LOADED_FEATURES.dup
  end

  config.after :each, :app_integration do
    # Tear down Zeitwerk (from zeitwerk's own test/support/loader_test)
    Zeitwerk::Registry.loaders.each(&:unload)
    Zeitwerk::Registry.loaders.clear

    # This private interface changes between 2.5.4 and 2.6.0
    if Zeitwerk::Registry.respond_to?(:loaders_managing_gems)
      Zeitwerk::Registry.loaders_managing_gems.clear
    else
      Zeitwerk::Registry.gem_loaders_by_root_file.clear
      Zeitwerk::Registry.autoloads.clear
      Zeitwerk::Registry.inceptions.clear
    end

    Zeitwerk::ExplicitNamespace.cpaths.clear
    Zeitwerk::ExplicitNamespace.tracer.disable

    if Hanami.instance_variable_defined?(:@_app)
      Hanami.remove_instance_variable(:@_app)
    end

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

    application_modules.each do |app_module_name|
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

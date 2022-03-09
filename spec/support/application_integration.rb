# frozen_string_literal: true

require "hanami/devtools/integration/files"
require "hanami/devtools/integration/with_tmp_directory"
require "zeitwerk"

RSpec.shared_context "Application integration" do
  let(:application_modules) { %i[TestApp Admin Main Search] }
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, :application_integration
  config.include RSpec::Support::WithTmpDirectory, :application_integration
  config.include_context "Application integration", :application_integration

  config.before :each, :application_integration do
    @load_paths = $LOAD_PATH.dup
  end

  config.after :each, :application_integration do
    # Tear down Zeitwerk (from zeitwerk's own test/support/loader_test)
    Zeitwerk::Registry.loaders.each(&:unload)
    Zeitwerk::Registry.loaders.clear
    Zeitwerk::Registry.loaders_managing_gems.clear
    Zeitwerk::ExplicitNamespace.cpaths.clear
    Zeitwerk::ExplicitNamespace.tracer.disable

    if Hanami.instance_variable_defined?(:@_application)
      Hanami.remove_instance_variable(:@_application)
    end

    $LOAD_PATH.replace(@load_paths)
    $LOADED_FEATURES.delete_if do |feature_path|
      feature_path =~ %r{hanami/(setup|prepare|boot|application/container/providers)}
    end

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
end

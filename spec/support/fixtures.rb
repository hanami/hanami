# Please use this app only for:
#
#   * spec/unit/application_spec.rb
#   * spec/isolation/application_configure_spec.rb
module UnitTesting
  class Application < Hanami::Application
  end
end

# Please use this app only for:
#
#   * spec/unit/application_configuration_spec.rb
module ApplicationConfigurationTesting
  class Application < Hanami::Application
  end
end

# Please use this mock logger only for:
#
#   * spec/isolation/components/logger/with_custom_logger_spec.rb
class SemanticLogger
  def initialize(*)
  end

  def info(*)
  end

  def warn(*)
  end

  def debug(*)
  end
end

module HelpersTestHelpers

protected

  class EmulatedConfigObject
    def self.configuration()
      self
    end

    def self.reset_config(conf = {})
      @_mocked_attributes = conf
    end

    def self.method_missing(attr_name)
      @_mocked_attributes ||= {}
      @_mocked_attributes.has_key?(attr_name) ? @_mocked_attributes[attr_name] : nil
    end
  end

public

  module ConfigStub
    class Application < HelpersTestHelpers::EmulatedConfigObject
    end
  end
end

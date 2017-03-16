# @api private
module Hanami::Mailer
  # @since 0.5.0
  # @api private
  module Glue
    # @since 0.5.0
    # @api private
    def self.included(configuration)
      configuration.class_eval do
        alias_method :delivery, :delivery_method
      end
    end
  end

  Configuration.class_eval do
    include Glue
  end
end

# @since 0.5.0
# @api private
module Mailers
end

Hanami::Mailer.configure do
  namespace Mailers
end

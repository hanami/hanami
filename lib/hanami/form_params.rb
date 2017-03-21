require 'json'

module Hanami
  # Formatted and filtered form params for CommonLogger
  #
  # @since x.x.x
  # @api private
  class FormParams
    def initialize(params)
      @params = params && Hanami::Utils::Hash.new(params).deep_symbolize!
    end

    # @since x.x.x
    # @api private
    def prepared_params
      return unless present?

      @prepared_params ||= JSON.pretty_generate(@params.to_h)
    end

    # @since x.x.x
    # @api private
    def log_message
      return unless present?

      "Parameters: #{prepared_params}"
    end

    # @since x.x.x
    # @api private
    def present?
      !@params.nil?
    end
  end
end

module Hanami
  #  Filtered form params for CommonLogger
  #
  # @since x.x.x
  # @api private
  class FormParams
    class InvalidFilteredParameterTypeException < StandardError; end

    def initialize(params)
      @params = params
    end

    # @since x.x.x
    # @api private
    def prepared_params
      return unless present?

      Hanami::Utils::Hash.new(@params).deep_symbolize!.to_h
    end

    # @since x.x.x
    # @api private
    def present?
      !@params.nil?
    end
  end
end

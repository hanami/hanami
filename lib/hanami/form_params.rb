require 'json'

module Hanami
  # Formatted and filtered form params for CommonLogger
  #
  # @since x.x.x
  # @api private
  class FormParams
    def initialize(params, filtered_parameters: Hanami.configuration.filtered_parameters)
      @params = params
      @filtered_parameters = filtered_parameters
    end

    # @since x.x.x
    # @api private
    def prepared_params
      return unless present?

      @prepared_params ||= JSON.pretty_generate(filtered_params.deep_symbolize!.to_h)
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

    private

    def filtered_params
      filtered_params = if @filtered_parameters.nil?
                          @params
                        else
                          filter_hash(@params)
                        end

      Hanami::Utils::Hash.new(filtered_params)
    end

    def filter_hash(hash)
      Hash[
        hash.map do |k, v|
          if filtered_key?(k)
            [k, '[FILTERED]']
          else
            [k, process_hash_value(v)]
          end
        end
      ]
    end

    def process_hash_value(v)
      return v unless v.is_a?(Hash)

      filter_hash(v)
    end

    def filtered_key?(key)
      @filtered_parameters.any? do |filter|
        processed_filter = filter.is_a?(Symbol) ? filter.to_s : filter

        key.match?(processed_filter)
      end
    end
  end
end

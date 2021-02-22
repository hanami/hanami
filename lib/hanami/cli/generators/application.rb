# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      module Application
        class << self
          def call(architecture, fs, inflector)
            require_relative "#{__dir__}/application/#{architecture}"

            generator_name = inflector.classify(architecture).to_sym
            const_get(generator_name).new(fs: fs, inflector: inflector)
          end
          alias_method :[], :call
        end
      end
    end
  end
end

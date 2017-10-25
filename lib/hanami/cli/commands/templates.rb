module Hanami
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class Templates
        NAMESPACE = name.sub(Utils::String.demodulize(name), "").freeze

        # @since 1.1.0
        # @api private
        def initialize(klass)
          word = klass.name.sub(NAMESPACE, "").split("::").map(&:downcase)
          @root = Pathname.new(File.join(__dir__, *word))
          freeze
        end

        # @since 1.1.0
        # @api private
        def find(*names)
          @root.join(*names)
        end

        private

        # @since 1.1.0
        # @api private
        attr_reader :root
      end
    end
  end
end

module Hanami
  class CLI
    module Commands
      class Templates
        NAMESPACE = name.sub(Utils::String.new(name).demodulize, "").freeze

        def initialize(class_name)
          word = class_name.sub(NAMESPACE, "").split("::").map(&:downcase)
          @root = Pathname.new(File.join(__dir__, *word))
          freeze
        end

        def find(*names)
          @root.join(*names)
        end

        private

        attr_reader :root
      end
    end
  end
end

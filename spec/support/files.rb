module RSpec
  module Support
    module Files
      private

      def write(path, *content)
        open(path, ::File::CREAT | ::File::WRONLY, *content)
      end

      def rewrite(path, *content)
        open(path, ::File::TRUNC | ::File::WRONLY, *content)
      end

      def open(path, mode, *content)
        ::File.open(path, mode) do |file|
          file.write(Array(content).flatten.join)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, type: :cli
end

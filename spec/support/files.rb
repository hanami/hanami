module RSpec
  module Support
    module Files
      private

      def rewrite(path, *content)
        ::File.open(path, ::File::TRUNC | ::File::WRONLY) do |file|
          file.write(Array(content).flatten.join)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, type: :cli
end

module RSpec
  module Support
    module Files
      private

      def write(path, *content)
        Pathname.new(path).dirname.mkpath
        open(path, ::File::CREAT | ::File::WRONLY, *content)
      end

      def rewrite(path, *content)
        open(path, ::File::TRUNC | ::File::WRONLY, *content)
      end

      def replace(path, target, replacement)
        content = ::File.readlines(path)
        content[index(content, path, target)] = "#{replacement}\n"

        rewrite(path, content)
      end

      def replace_last(path, target, replacement)
        content = ::File.readlines(path)
        content[-index(content.reverse, path, target) - 1] = "#{replacement}\n"

        rewrite(path, content)
      end

      def unshift(path, line)
        content = ::File.readlines(path)
        content.unshift("#{line}\n")

        rewrite(path, content)
      end

      def append(path, contents)
        content = ::File.readlines(path)
        content << "#{contents}\n"

        rewrite(path, content)
      end

      def open(path, mode, *content)
        ::File.open(path, mode) do |file|
          file.write(Array(content).flatten.join)
        end
      end

      def index(content, path, target)
        content.index { |l| l.include?(target) } or
          raise ArgumentError.new("Cannot find `#{target}' inside `#{path}'.")
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, type: :cli
end

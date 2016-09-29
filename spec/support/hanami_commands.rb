require_relative 'bundler'
require_relative 'files'
require 'hanami/utils/string'

module RSpec
  module Support
    module HanamiCommands
      private

      def hanami(cmd, &blk)
        bundle_exec "hanami #{cmd}", &blk
      end

      def server(args = {}, &blk)
        hanami "server#{_hanami_server_args(args)}" do |_, _, wait_thr|
          begin
            if block_given?
              setup_capybara(args)
              retry_exec(&blk)
            end
          ensure
            # Simulate Ctrl+C to stop the server
            Process.kill 'INT', wait_thr[:pid]
          end
        end
      end

      def console(&blk)
        hanami "console", &blk
      end

      def generate(target)
        hanami "generate #{target}"
      end

      def migrate
        hanami "db migrate"
      end

      def generate_model(entity)
        generate "model #{entity}"
      end

      def generate_migration(name, content)
        generate "migration #{name}"

        last_migration = Pathname.new("db").join("migrations").children.last
        rewrite(last_migration, content)

        last_migration.basename.to_s.to_i
      end

      # FIXME: remove when we will integrate hanami-model 0.7
      def entity(name, project, *attributes)
        path = Pathname.new("lib").join(project, "entities", "#{name}.rb")

        class_name = Hanami::Utils::String.new(name).classify
        content    = <<-EOF
class #{class_name}
  include Hanami::Entity
  attributes #{attributes.map { |a| ":#{a}" }.join(', ')}
end
EOF

        rewrite(path, content)
      end

      # FIXME: remove when we will integrate hanami-model 0.7
      def mapping(project, content)
        path  = Pathname.new("lib").join("#{project}.rb") # lib/bookshelf.rb

        lines = ::File.readlines(path)
        index = lines.index { |l| l =~ %r{mapping do} } + 1

        lines.insert(index, content)
        rewrite(path, lines.flatten)
      end

      def setup_capybara(args)
        host = args.fetch(:host, Hanami::Environment::LISTEN_ALL_HOST)
        port = args.fetch(:port, Hanami::Environment::DEFAULT_PORT)

        Capybara.configure do |config|
          config.app_host = "http://#{host}:#{port}"
        end
      end

      def retry_exec(&blk)
        attempts = 1

        begin
          sleep 1
          blk.call # rubocop:disable Performance/RedundantBlockCall
        rescue Capybara::Webkit::InvalidResponseError
          raise if attempts > 3
          attempts += 1
          retry
        end
      end

      def _hanami_server_args(args)
        return if args.empty?

        result = args.map do |arg, value|
          if value.nil?
            "--#{arg}"
          else
            "--#{arg}=#{value}"
          end
        end.join(" ")

        " #{result}"
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::HanamiCommands, type: :cli
end

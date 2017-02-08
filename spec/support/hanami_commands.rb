require_relative 'bundler'
require_relative 'files'
require_relative 'retry'
require 'hanami/utils/string'

module RSpec
  module Support
    module HanamiCommands
      private

      def rackup(args = {}, &blk)
        bundle_exec "rackup -p 2300" do |_, _, wait_thr|
          exec_server_tests(args, wait_thr, &blk)
        end
      end

      def server(args = {}, &blk)
        hanami "server#{_hanami_server_args(args)}" do |_, _, wait_thr|
          exec_server_tests(args, wait_thr, &blk)
        end
      end

      def hanami(cmd, env: nil, &blk)
        bundle_exec("hanami #{cmd}", env: env, &blk)
      end

      def console(&blk)
        hanami "console", &blk
      end

      def db_console(&blk)
        hanami "db console", &blk
      end

      def generate(target)
        hanami "generate #{target}"
      end

      def destroy(target)
        hanami "destroy #{target}"
      end

      def migrate
        hanami "db migrate"
      end

      def generate_model(entity)
        generate "model #{entity}"
      end

      def generate_migration(name, content)
        # Check if the migration already exist because `hanami generate model`
        migration = Dir.glob(Pathname.new("db").join("migrations", "*_#{name}.rb")).sort.last

        # If it doesn't exist, generate it
        if migration.nil?
          sleep 1 # prevent two migrations to have the same timestamp
          generate "migration #{name}"

          migration = Dir.glob(Pathname.new("db").join("migrations", "**", "*.rb")).sort.last
        end

        # write the given content, then return the timestamp
        rewrite(migration, content)
        Integer(migration.scan(/[0-9]+/).first)
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Style/ClosingParenthesisIndentation
      def generate_migrations
        versions = []
        versions << generate_migration("create_users", <<-EOF
Hanami::Model.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String
    end
  end
end
EOF
)

        versions << generate_migration("add_age_to_users", <<-EOF
Hanami::Model.migration do
  change do
    add_column :users, :age, Integer
  end
end
EOF
)
        versions
      end
      # rubocop:enable Style/ClosingParenthesisIndentation
      # rubocop:enable Metrics/MethodLength

      def setup_model # rubocop:disable Metrics/MethodLength
        generate_model     "book"
        generate_migration "create_books", <<-EOF
Hanami::Model.migration do
  change do
    create_table :books do
      primary_key :id
      column :title, String
    end
  end
end
        EOF

        migrate
      end

      def exec_server_tests(args, wait_thr, &blk)
        if block_given?
          setup_capybara(args)
          retry_exec(StandardError, &blk)
        end
      ensure
        # Simulate Ctrl+C to stop the server
        Process.kill 'INT', wait_thr[:pid]
      end

      def setup_capybara(args)
        host = args.fetch(:host, Hanami::Environment::LISTEN_ALL_HOST)
        port = args.fetch(:port, Hanami::Environment::DEFAULT_PORT)

        Capybara.configure do |config|
          config.app_host = "http://#{host}:#{port}"
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

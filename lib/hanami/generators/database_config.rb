require 'shellwords'

module Hanami
  # @api private
  module Generators
    # @api private
    class DatabaseConfig

      # @api private
      SUPPORTED_ENGINES = {
        'mysql'      => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
        'mysql2'     => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
        'postgresql' => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
        'postgres'   => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
        'sqlite'     => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  },
        'sqlite3'    => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  }
      }.freeze

      # @api private
      DEFAULT_ENGINE = 'sqlite'.freeze

      # @api private
      attr_reader :engine
      # @api private
      attr_reader :name

      # @api private
      def initialize(engine, name)
        @engine = engine
        @name = name

        unless SUPPORTED_ENGINES.key?(engine.to_s) # rubocop:disable Style/GuardClause
          warn %(`#{engine}' is not a valid database engine)
          exit(1)
        end
      end

      # @api private
      def to_hash
        {
          gem: gem,
          uri: uri,
          type: type
        }
      end

      # @api private
      def type
        SUPPORTED_ENGINES[engine][:type]
      end

      # @api private
      def sql?
        type == :sql
      end

      # @api private
      def sqlite?
        ['sqlite', 'sqlite3'].include?(engine)
      end

      private

      # @api private
      def platform
        Hanami::Utils.jruby? ? :jruby : :mri
      end

      # @api private
      def platform_prefix
        'jdbc:'.freeze if Hanami::Utils.jruby?
      end

      # @api private
      def uri
        {
          development: environment_uri(:development),
          test: environment_uri(:test)
        }
      end

      # @api private
      def gem
        SUPPORTED_ENGINES[engine][platform]
      end

      # @api private
      def base_uri
        case engine
        when 'mysql', 'mysql2'
          if Hanami::Utils.jruby?
            "mysql://localhost/#{ name }"
          else
            "mysql2://localhost/#{ name }"
          end
        when 'postgresql', 'postgres'
          "postgresql://localhost/#{ name }"
        when 'sqlite', 'sqlite3'
          "sqlite://db/#{ Shellwords.escape(name) }"
        end
      end

      # @api private
      def environment_uri(environment)
        case engine
        when 'sqlite', 'sqlite3'
          "#{ platform_prefix }#{ base_uri }_#{ environment }.sqlite"
        else
          "#{ platform_prefix if sql? }#{ base_uri }_#{ environment }"
        end
      end
    end
  end
end

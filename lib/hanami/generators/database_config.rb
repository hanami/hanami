require 'shellwords'

module Hanami
  module Generators
    class DatabaseConfig

      SUPPORTED_ENGINES = {
        'mysql'      => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
        'mysql2'     => { type: :sql,         mri: 'mysql2',  jruby: 'jdbc-mysql'    },
        'postgresql' => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
        'postgres'   => { type: :sql,         mri: 'pg',      jruby: 'jdbc-postgres' },
        'sqlite'     => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  },
        'sqlite3'    => { type: :sql,         mri: 'sqlite3', jruby: 'jdbc-sqlite3'  },
        'filesystem' => { type: :file_system, mri: nil,       jruby: nil             },
        'memory'     => { type: :memory,      mri: nil,       jruby: nil             }
      }.freeze

      DEFAULT_ENGINE = 'filesystem'.freeze

      attr_reader :engine, :name

      def initialize(engine, name)
        @engine = engine
        @name = name

        SUPPORTED_ENGINES.key?(engine.to_s) or fail "\"#{ engine }\" is not a valid database type"
      end

      def to_hash
        {
          gem: gem,
          uri: uri,
          type: type
        }
      end

      def type
        SUPPORTED_ENGINES[engine][:type]
      end

      def sql?
        type == :sql
      end

      def filesystem?
        type == :file_system
      end

      private

      def platform
        Hanami::Utils.jruby? ? :jruby : :mri
      end

      def platform_prefix
        'jdbc:'.freeze if Hanami::Utils.jruby?
      end

      def uri
        {
          development: environment_uri(:development),
          test: environment_uri(:test)
        }
      end

      def gem
        SUPPORTED_ENGINES[engine][platform]
      end

      def base_uri
        case engine
        when 'mysql', 'mysql2'
          if Hanami::Utils.jruby?
            "mysql://localhost/#{ name }"
          else
            "mysql2://localhost/#{ name }"
          end
        when 'postgresql', 'postgres'
          "postgres://localhost/#{ name }"
        when 'sqlite', 'sqlite3'
          "sqlite://db/#{ Shellwords.escape(name) }"
        when 'memory'
          "memory://localhost/#{ name }"
        when 'filesystem'
          "file:///db/#{ Shellwords.escape(name) }"
        end
      end

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

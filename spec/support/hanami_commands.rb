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
      end

      # FIXME: remove when we will integrate hanami-model 0.7
      def entity(name, project, *attributes)
        path = Pathname.new("lib").join(project, "entities", "#{name}.rb")

        class_name = Hanami::Utils::String.new(name).classify
        content    = <<-EOF
class #{class_name}
  include Hanami::Entity
  attributes #{attributes.join(', ')}
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
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::HanamiCommands, type: :cli
end

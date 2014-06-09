require 'lotus/utils/load_paths'

module Lotus
  module Config
    class LoadPaths < Utils::LoadPaths
      PATTERN = '**/*.rb'.freeze

      def load!
        each do |path|
          Dir.glob(path.join(PATTERN)).each {|file| require file }
        end
      end
    end
  end
end


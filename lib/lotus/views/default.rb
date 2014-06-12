module Lotus
  module Views
    class Default
      include Lotus::View
      configuration.reset!

      layout nil
      root Pathname.new(File.dirname(__FILE__)).join('../templates').realpath
      template 'default'

      def title
        response[2].first
      end
    end
  end
end

module Posts
  class Controller
    include Lotus::Controller

    action 'Index' do
      def call(params)
      end
    end

    action 'Raise' do
      def call(params)
        raise "I've got a problem"
      end
    end
  end
end

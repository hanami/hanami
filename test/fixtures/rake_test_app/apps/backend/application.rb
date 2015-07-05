module Backend
  class Application < Lotus::Application
    configure do
      root File.dirname(__FILE__)
      load_paths << []
    end
  end
end

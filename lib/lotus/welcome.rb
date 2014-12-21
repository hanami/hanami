require 'pathname'

module Lotus
  class Welcome
    def initialize(app)
      @root = Pathname.new(__dir__).join('templates').realpath
      @body = [@root.join('welcome.html').read]
    end

    def call(env)
      [200, {}, @body]
    end
  end
end

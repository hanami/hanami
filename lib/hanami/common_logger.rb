module Hanami
  class CommonLogger < ::Rack::CommonLogger
    EMPTY_STRING = ''.freeze
    ROOT_PATH = '/'.freeze

    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      log(env, status, header, began_at)

      [status, header, body]
    end

  private

    def log(env, status, header, began_at)
      msg = generate_message(env, status, began_at)
      length = extract_content_length(header)
      msg[:length] = length if length

      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      @logger.log(@logger.level, msg)
    end

    def full_path(env)
      path = env['PATH_INFO'].empty? ? ROOT_PATH : env['PATH_INFO']
      query = env['QUERY_STRING'].empty? ? EMPTY_STRING : "?#{env['QUERY_STRING']}"

      path + query
    end

    def extract_content_length(header)
      value = header['Content-Length'] || return
      value.to_s == '0' ? nil : value
    end

    def generate_message(env, status, began_at)
      now = Time.now

      {
        addr: env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'],
        now_time: now.strftime("'%d/%b/%Y %H:%M:%S %z'"),
        request_method: env['REQUEST_METHOD'],
        path: full_path(env).inspect,
        http_version: env['HTTP_VERSION'],
        status: status.to_s[0..3],
        time: now - began_at
      }
    end
  end
end

module Rack
  class CommonLogger
    def call(env)
      @app.call(env)
    end
  end
end

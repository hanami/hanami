module Hanami
  class CommonLogger < ::Rack::CommonLogger
    EMPTY_STRING = ''.freeze

    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      log(env, status, header, began_at)

      [status, header, body]
    end

  private

    def log(env, status, header, began_at)
      now = Time.now

      msg = {
        addr: env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'],
        now_time: now.strftime("'%d/%b/%Y %H:%M:%S %z'"),
        request_method: env['REQUEST_METHOD'],
        path: env['PATH_INFO'] + query_string(env),
        http_version: env['HTTP_VERSION'],
        length: extract_content_length(header),
        status: status.to_s[0..3],
        time: now - began_at
      }

      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      @logger.log(@logger.level, msg)
    end

    def query_string(env)
      env['QUERY_STRING'].empty? ? EMPTY_STRING : "?#{env['QUERY_STRING']}"
    end

    def extract_content_length(header)
      value = header['Content-Length'] or return
      value.to_s == '0' ? nil : value
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

module Hanami
  class CommonLogger < ::Rack::CommonLogger
    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      log(env, status, header, began_at)
      [status, header, body]
    end

  private

    def log(env, status, header, began_at)
      now = Time.now
      length = extract_content_length(header)

      msg = {
        addr: env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'],
        user: env["REMOTE_USER"],
        now_time: now.strftime("%d/%b/%Y:%H:%M:%S %z"),
        request_method: env['REQUEST_METHOD'],
        path: env['PATH_INFO'],
        query_string: env['QUERY_STRING'].empty? ? nil : "?#{env['QUERY_STRING']}",
        http_version: env['HTTP_VERSION'],
        status: status.to_s[0..3],
        length: length,
        time: now - began_at
      }

      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      @logger.log(@logger.level, msg)
    end

    def extract_content_length(headers)
      value = headers['Content-Length'] or return
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

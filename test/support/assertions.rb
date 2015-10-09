module Minitest
  module Assertions
    def assert_exception_raised(exception_klass, message = nil, &block)
      exception = block.must_raise exception_klass
      exception.message.must_equal(message) if message
    end

    # Compare file contents and ignore line endings and empty lines
    def assert_generated_file(expected, actual)
      assert_file_exists(expected)
      assert_file_exists(actual)

      expected_content = File.read(expected)
      actual_content = File.read(actual)

      sanitized_expected_content = expected_content.chomp.gsub(/\r\n?/, "\n").gsub(/^\n/, '')
      sanitized_actual_content = actual_content.chomp.gsub(/\r\n?/, "\n").gsub(/^\n/, '')
      assert_equal sanitized_expected_content, sanitized_actual_content
    end

    def assert_file_exists(expected)
      assert File.exist?(expected), "Expected #{expected} to exist but does not."
    end

    def refute_file_exists(expected)
      refute File.exist?(expected), "Expected #{expected} to NOT exist but does."
    end

    # Asserts a given file have a content.
    # If the argument is a regexp, it will check if the regular expression
    # matches the given file content. If it's a string, it check if the
    # file includes the given string:
    def assert_file_includes(expected, *contents)
      assert_file_exists(expected)

      read = File.read(expected)

      contents.each do |content|
        case content
        when String
          assert read.include?(content), "Expected #{read} to include #{content} but does not."
        when Regexp
          assert_match content, read
        end
      end
    end

    def refute_file_includes(expected, *contents)
      assert_file_exists(expected)

      read = File.read(expected)

      contents.each do |content|
        case content
        when String
          refute read.include?(content), "Expected #{read} to NOT include #{content} but does."
        when Regexp
          refute_match content, read
        end
      end
    end
  end
end

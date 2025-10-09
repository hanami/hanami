#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "fileutils"

# Load local Hanami development version
require_relative "../lib/hanami"

def create_app_with_config(temp_dir, memoize:, component_count:)
  # Create minimal app structure
  FileUtils.mkdir_p("#{temp_dir}/config/slices")
  FileUtils.mkdir_p("#{temp_dir}/slices/main/actions")
  FileUtils.mkdir_p("#{temp_dir}/slices/main/views")

  # Create minimal app config
  File.write("#{temp_dir}/config/app.rb", <<~RUBY)
    require "hanami"

    module MemoryApp
      class App < Hanami::App
        config.root = "#{temp_dir}"
      end
    end
  RUBY

  # Create slice config with memoization setting
  File.write("#{temp_dir}/config/slices/main.rb", <<~RUBY)
    module Main
      class Slice < Hanami::Slice
        config.memoize_component_dirs = #{memoize ? '["actions/", "views/"]' : "[]"}
      end
    end
  RUBY

  # Create multiple components to simulate a real app
  # Note: Using simple classes instead of Hanami::Action/View to avoid frozen object constraints
  component_count.times do |i|
    File.write("#{temp_dir}/slices/main/actions/action_#{i}.rb", <<~RUBY)
      module Main
        module Actions
          class Action#{i}
            def initialize
              @created_at = Time.now.to_f
              @name = "Action#{i}"
              @data = { key: "value" * 10 }
              @array = Array.new(100) { |j| j }
            end

            def call(env = {})
              { status: 200, name: @name, data: @data }
            end
          end
        end
      end
    RUBY

    File.write("#{temp_dir}/slices/main/views/view_#{i}.rb", <<~RUBY)
      module Main
        module Views
          class View#{i}
            def initialize
              @created_at = Time.now.to_f
              @name = "View#{i}"
              @data = { key: "value" * 10 }
              @array = Array.new(100) { |j| j }
            end

            def render(data = {})
              { view: @name, data: data }
            end
          end
        end
      end
    RUBY
  end

  temp_dir
end

def measure_memory_usage(memoize:, resolutions:, component_count:)
  temp_dir = Dir.mktmpdir("hanami_memory_benchmark")

  begin
    create_app_with_config(temp_dir, memoize: memoize, component_count: component_count)

    # Create a separate Ruby script to measure memory in a fresh process
    script = <<~RUBY
      def get_memory_usage
        if RUBY_PLATFORM.match?(/darwin/)
          `ps -o rss= -p \#{Process.pid}`.to_i
        elsif RUBY_PLATFORM.match?(/linux/)
          `ps -o rss= -p \#{Process.pid}`.to_i
        else
          `ps -o rss= -p \#{Process.pid}`.to_i
        end
      end

      Dir.chdir("#{temp_dir}")
      require "./config/app"
      require "hanami/prepare"

      GC.start
      sleep 0.1

      memory_before = get_memory_usage

      #{resolutions}.times do
        #{component_count}.times do |i|
          Main::Slice["actions.action_\#{i}"]
          Main::Slice["views.view_\#{i}"]
        end
      end

      GC.start
      sleep 0.1

      memory_after = get_memory_usage

      puts "\#{memory_before},\#{memory_after}"
    RUBY

    script_path = "#{temp_dir}/measure_memory.rb"
    File.write(script_path, script)

    # Run in a separate process to avoid config freezing issues
    rubylib_path = File.expand_path("../lib", __dir__)
    hanami_root = File.expand_path("..", __dir__)
    output = `cd "#{hanami_root}" && RUBYLIB="#{rubylib_path}" bundle exec ruby "#{script_path}" 2>/dev/null`

    if output.strip.empty?
      # Fallback: try with errors visible
      output = `cd "#{hanami_root}" && RUBYLIB="#{rubylib_path}" bundle exec ruby "#{script_path}"`
      warn "Warning: memory measurement failed. Output: #{output}"
      {before: 0, after: 0, delta: 0}
    else
      result_line = output.strip
      memory_before, memory_after = result_line.split(",").map(&:to_i)

      {
        before: memory_before,
        after: memory_after,
        delta: memory_after - memory_before,
      }
    end
  ensure
    FileUtils.rm_rf(temp_dir)
  end
end

def format_memory(kb)
  if kb > 1024
    "#{(kb / 1024.0).round(2)} MB"
  else
    "#{kb} KB"
  end
end

def run_memory_benchmark(component_count:)
  app_size = component_count <= 50 ? "SMALL" : "LARGE"
  puts "=== HANAMI MEMORY USAGE BENCHMARK (#{app_size} APP) ==="
  puts "Simulating app with #{component_count} actions + #{component_count} views"
  puts "Measuring memory usage with and without memoization"
  puts

  resolution_counts = [100, 1000, 5000, 10_000]

  resolution_counts.each do |resolutions|
    puts
    puts "=" * 60
    puts "TEST: Resolving #{component_count * 2} components (#{component_count} actions + #{component_count} views) #{resolutions} times"
    puts "=" * 60
    puts

    # Measure normal (non-memoized) - each resolution creates new instance
    print "Measuring normal (non-memoized) configuration... "
    normal_result = measure_memory_usage(memoize: false, resolutions: resolutions, component_count: component_count)
    puts "Done"

    # Measure memoized - each resolution returns cached instance
    print "Measuring memoized configuration... "
    memoized_result = measure_memory_usage(memoize: true, resolutions: resolutions, component_count: component_count)
    puts "Done"

    puts
    puts "RESULTS:"
    puts

    puts "Normal (no memoization):"
    puts "  Before: #{format_memory(normal_result[:before])}"
    puts "  After:  #{format_memory(normal_result[:after])}"
    puts "  Delta:  #{format_memory(normal_result[:delta])}"
    puts

    puts "Memoized:"
    puts "  Before: #{format_memory(memoized_result[:before])}"
    puts "  After:  #{format_memory(memoized_result[:after])}"
    puts "  Delta:  #{format_memory(memoized_result[:delta])}"
    puts

    memory_saved = normal_result[:delta] - memoized_result[:delta]
    if memory_saved.positive?
      percent_saved = ((memory_saved.to_f / normal_result[:delta]) * 100).round(2)
      puts "Memory saved by memoization: #{format_memory(memory_saved)} (#{percent_saved}%)"
    elsif memory_saved.negative?
      percent_increase = ((memory_saved.abs.to_f / normal_result[:delta]) * 100).round(2)
      puts "Additional memory used by memoization: #{format_memory(memory_saved.abs)} (#{percent_increase}%)"
    else
      puts "Memory usage: No significant difference"
    end
  end

  puts
  puts "=" * 60
  puts "SUMMARY"
  puts "=" * 60
  puts
  puts "Note: Memoization saves memory by reusing component instances instead"
  puts "of creating new objects on each resolution. The savings grow with the"
  puts "number of component resolutions."
  puts
  puts "Expected: Memoized should use significantly less memory when components"
  puts "are resolved many times, as instances are cached rather than recreated."
  puts
  puts "Component pool size affects savings:"
  puts "- Small apps (20-50 components): Higher percentage savings (60-80%)"
  puts "- Large apps (200+ components): Lower percentage savings (10-30%)"
end

if __FILE__ == $0
  component_count = (ARGV[0] || 20).to_i
  run_memory_benchmark(component_count: component_count)
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "fileutils"
require "benchmark"

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

    module StartupApp
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
              @data = {}
            end

            def call(env = {})
              { status: 200, name: @name }
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
              @data = {}
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

def measure_startup_time(memoize:, component_count:)
  temp_dir = Dir.mktmpdir("hanami_startup_benchmark")

  begin
    create_app_with_config(temp_dir, memoize: memoize, component_count: component_count)

    # Create a separate Ruby script to load the app in a fresh process
    script = <<~RUBY
      require "benchmark"
      Dir.chdir("#{temp_dir}")
      startup_time = Benchmark.realtime do
        require "./config/app"
        require "hanami/prepare"
      end
      puts startup_time
    RUBY

    script_path = "#{temp_dir}/measure.rb"
    File.write(script_path, script)

    # Run in a separate process to avoid config freezing issues
    rubylib_path = File.expand_path("../lib", __dir__)
    hanami_root = File.expand_path("..", __dir__)
    output = `cd "#{hanami_root}" && RUBYLIB="#{rubylib_path}" bundle exec ruby "#{script_path}" 2>/dev/null`

    if output.strip.empty?
      # Fallback: try with errors visible
      output = `cd "#{hanami_root}" && RUBYLIB="#{rubylib_path}" bundle exec ruby "#{script_path}"`
      warn "Warning: startup measurement failed. Output: #{output}"
      0.0
    else
      output.strip.to_f
    end
  ensure
    FileUtils.rm_rf(temp_dir)
  end
end

def run_startup_benchmark(component_count:)
  app_size = component_count <= 50 ? "SMALL" : "LARGE"
  puts "=== HANAMI STARTUP TIME BENCHMARK (#{app_size} APP) ==="
  puts "Simulating app with #{component_count} actions + #{component_count} views"
  puts "Measuring app initialization time with and without memoization"
  puts

  iterations = 5
  memoized_times = []
  normal_times = []

  puts "Running #{iterations} iterations for each configuration..."
  puts

  iterations.times do |i|
    print "Iteration #{i + 1}/#{iterations}: "

    # Measure normal (non-memoized)
    normal_time = measure_startup_time(memoize: false, component_count: component_count)
    normal_times << normal_time
    print "Normal: #{(normal_time * 1000).round(2)}ms, "

    # Measure memoized
    memoized_time = measure_startup_time(memoize: true, component_count: component_count)
    memoized_times << memoized_time
    print "Memoized: #{(memoized_time * 1000).round(2)}ms"
    puts
  end

  puts
  puts "=" * 60
  puts "RESULTS (averaged over #{iterations} runs):"
  puts "=" * 60

  avg_normal = normal_times.sum / normal_times.size
  avg_memoized = memoized_times.sum / memoized_times.size

  puts
  puts "Normal (no memoization):"
  puts "  Average: #{(avg_normal * 1000).round(2)}ms"
  puts "  Min: #{(normal_times.min * 1000).round(2)}ms"
  puts "  Max: #{(normal_times.max * 1000).round(2)}ms"
  puts

  puts "Memoized:"
  puts "  Average: #{(avg_memoized * 1000).round(2)}ms"
  puts "  Min: #{(memoized_times.min * 1000).round(2)}ms"
  puts "  Max: #{(memoized_times.max * 1000).round(2)}ms"
  puts

  diff = avg_memoized - avg_normal
  diff_percent = ((diff / avg_normal) * 100).round(2)

  if diff.abs < 0.001
    puts "Difference: Negligible (< 1ms)"
  elsif diff.positive?
    puts "Difference: +#{(diff * 1000).round(2)}ms (#{diff_percent}% slower)"
  else
    puts "Difference: #{(diff * 1000).round(2)}ms (#{diff_percent.abs}% faster)"
  end

  puts
  puts "Note: Startup time should be similar for both configurations."
  puts "Memoization affects runtime component resolution, not initial load time."
end

if __FILE__ == $0
  component_count = (ARGV[0] || 20).to_i
  run_startup_benchmark(component_count: component_count)
end

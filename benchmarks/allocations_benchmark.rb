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
        config.memoize_component_namespaces = #{memoize ? '["actions.", "views."]' : "[]"}
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

    # Create a separate Ruby script to measure allocations in a fresh process
    script = <<~RUBY
      Dir.chdir("#{temp_dir}")
      require "./config/app"
      require "hanami/prepare"

      GC.start
      GC.disable

      allocations_before = GC.stat[:total_allocated_objects]

      #{resolutions}.times do
        #{component_count}.times do |i|
          Main::Slice["actions.action_\#{i}"]
          Main::Slice["views.view_\#{i}"]
        end
      end

      allocations_after = GC.stat[:total_allocated_objects]

      GC.enable

      puts "\#{allocations_before},\#{allocations_after}"
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
      alloc_before, alloc_after = result_line.split(",").map(&:to_i)

      {
        before: alloc_before,
        after: alloc_after,
        delta: alloc_after - alloc_before,
      }
    end
  ensure
    FileUtils.rm_rf(temp_dir)
  end
end

def format_count(count)
  count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def run_memory_benchmark(component_count:)
  app_size = component_count <= 50 ? "SMALL" : "LARGE"
  puts "=== HANAMI MEMORY USAGE BENCHMARK (#{app_size} APP) ==="
  puts "Simulating app with #{component_count} actions + #{component_count} views"
  puts "Measuring object allocations with and without memoization"
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
    puts "  Allocations: #{format_count(normal_result[:delta])} objects"
    puts

    puts "Memoized:"
    puts "  Allocations: #{format_count(memoized_result[:delta])} objects"
    puts

    saved = normal_result[:delta] - memoized_result[:delta]
    if normal_result[:delta].positive?
      percent_saved = ((saved.to_f / normal_result[:delta]) * 100).round(2)
      puts "Allocations saved by memoization: #{format_count(saved)} objects (#{percent_saved}%)"
    end
  end

  puts
  puts "=" * 60
  puts "SUMMARY"
  puts "=" * 60
  puts
  puts "Note: Measures total object allocations (GC disabled) for deterministic results."
  puts "Memoization reuses cached instances instead of creating new objects on each resolution."
end

if __FILE__ == $0
  component_count = (ARGV[0] || 20).to_i
  run_memory_benchmark(component_count: component_count)
end

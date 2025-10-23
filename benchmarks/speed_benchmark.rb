#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "fileutils"
require "benchmark/ips"

# Load local Hanami development version
require_relative "../lib/hanami"

def create_app(temp_dir, component_count:)
  # Create minimal app structure
  FileUtils.mkdir_p("#{temp_dir}/config")
  FileUtils.mkdir_p("#{temp_dir}/config/slices")
  FileUtils.mkdir_p("#{temp_dir}/slices/memoized/actions")
  FileUtils.mkdir_p("#{temp_dir}/slices/memoized/views")
  FileUtils.mkdir_p("#{temp_dir}/slices/normal/actions")
  FileUtils.mkdir_p("#{temp_dir}/slices/normal/views")

  # Create minimal app config
  File.write("#{temp_dir}/config/app.rb", <<~RUBY)
    require "hanami"

    module SpeedApp
      class App < Hanami::App
        config.root = "#{temp_dir}"
      end
    end
  RUBY

  # Create memoized slice config
  File.write("#{temp_dir}/config/slices/memoized.rb", <<~RUBY)
    module Memoized
      class Slice < Hanami::Slice
        config.memoize_component_dirs = ["actions/", "views/"]
      end
    end
  RUBY

  # Create normal slice config
  File.write("#{temp_dir}/config/slices/normal.rb", <<~RUBY)
    module Normal
      class Slice < Hanami::Slice
        config.memoize_component_dirs = []
      end
    end
  RUBY

  # Create component classes
  component_count.times do |i|
    # Action code
    action_code = <<~RUBY
      def initialize
        @created_at = Time.now.to_f
        @name = "Action#{i}"
        @data = { key: "value" * 10 }
        @array = Array.new(100) { |j| j }
      end

      def call(env = {})
        { status: 200, name: @name, data: @data }
      end
    RUBY

    File.write("#{temp_dir}/slices/memoized/actions/action_#{i}.rb", <<~RUBY)
      module Memoized
        module Actions
          class Action#{i}
            #{action_code}
          end
        end
      end
    RUBY

    File.write("#{temp_dir}/slices/normal/actions/action_#{i}.rb", <<~RUBY)
      module Normal
        module Actions
          class Action#{i}
            #{action_code}
          end
        end
      end
    RUBY

    # View code
    view_code = <<~RUBY
      def initialize
        @created_at = Time.now.to_f
        @name = "View#{i}"
        @data = { key: "value" * 10 }
        @array = Array.new(100) { |j| j }
      end

      def render(data = {})
        { view: @name, data: data }
      end
    RUBY

    File.write("#{temp_dir}/slices/memoized/views/view_#{i}.rb", <<~RUBY)
      module Memoized
        module Views
          class View#{i}
            #{view_code}
          end
        end
      end
    RUBY

    File.write("#{temp_dir}/slices/normal/views/view_#{i}.rb", <<~RUBY)
      module Normal
        module Views
          class View#{i}
            #{view_code}
          end
        end
      end
    RUBY
  end

  temp_dir
end

def run_speed_benchmark(component_count:)
  temp_dir = Dir.mktmpdir("hanami_speed_benchmark")

  begin
    app_size = component_count <= 50 ? "SMALL" : "LARGE"
    puts "=== HANAMI SPEED BENCHMARK (#{app_size} APP) ==="
    puts "Creating Hanami application with #{component_count} actions + #{component_count} views per slice..."
    create_app(temp_dir, component_count: component_count)

    # Change to temp directory
    original_dir = Dir.pwd
    Dir.chdir(temp_dir)

    # Load the app
    require "./config/app"
    require "hanami/prepare"

    puts "Hanami application loaded!"
    puts
    puts "Configuration verification:"
    puts "Memoized slice memoize_component_dirs: #{Memoized::Slice.config.memoize_component_dirs}"
    puts "Normal slice memoize_component_dirs: #{Normal::Slice.config.memoize_component_dirs}"
    puts

    # Test memoization behavior
    puts "Testing memoization behavior:"

    # Actions
    action1 = Memoized::Slice["actions.action_0"]
    action2 = Memoized::Slice["actions.action_0"]
    puts "Memoized Actions - same instance: #{action1.object_id == action2.object_id}"

    action3 = Normal::Slice["actions.action_0"]
    action4 = Normal::Slice["actions.action_0"]
    puts "Normal Actions - same instance: #{action3.object_id == action4.object_id}"

    # Views
    view1 = Memoized::Slice["views.view_0"]
    view2 = Memoized::Slice["views.view_0"]
    puts "Memoized Views - same instance: #{view1.object_id == view2.object_id}"

    view3 = Normal::Slice["views.view_0"]
    view4 = Normal::Slice["views.view_0"]
    puts "Normal Views - same instance: #{view3.object_id == view4.object_id}"
    puts

    # Benchmark: Single component (best case for memoization)
    puts "=" * 60
    puts "=== SINGLE COMPONENT RESOLUTION (BEST CASE) ==="
    puts "Resolving the same action repeatedly"
    puts "=" * 60

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      x.report("Memoized (cached)") do
        Memoized::Slice["actions.action_0"]
      end

      x.report("Normal (new instance)") do
        Normal::Slice["actions.action_0"]
      end

      x.compare!
    end

    puts "\n" + "=" * 60

    # Benchmark: Random component access (realistic case)
    puts "=== RANDOM COMPONENT RESOLUTION (REALISTIC CASE) ==="
    puts "Resolving random actions from pool of #{component_count}"
    puts "=" * 60

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      x.report("Memoized (cached)") do
        idx = rand(component_count)
        Memoized::Slice["actions.action_#{idx}"]
      end

      x.report("Normal (new instance)") do
        idx = rand(component_count)
        Normal::Slice["actions.action_#{idx}"]
      end

      x.compare!
    end

    puts "\n" + "=" * 60

    # Benchmark: Sequential access (cache warming)
    puts "=== SEQUENTIAL COMPONENT RESOLUTION ==="
    puts "Resolving all #{component_count} actions in sequence"
    puts "=" * 60

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      counter_memoized = 0
      x.report("Memoized (cached)") do
        Memoized::Slice["actions.action_#{counter_memoized % component_count}"]
        counter_memoized += 1
      end

      counter_normal = 0
      x.report("Normal (new instance)") do
        Normal::Slice["actions.action_#{counter_normal % component_count}"]
        counter_normal += 1
      end

      x.compare!
    end

    puts "\n" + "=" * 60
    puts "SUMMARY"
    puts "=" * 60
    puts
    puts "Expected results:"
    puts "- Single component: Memoized should be MUCH faster (no object creation)"
    puts "- Random access: Memoized should be faster (cache hit rate depends on pool size)"
    puts "- Sequential: Memoized should be faster (all cached after first pass)"
    puts
    puts "Component pool size affects speedup:"
    puts "- Small apps (20-50 components): Higher speedup (8-10x faster)"
    puts "- Large apps (200+ components): Still significant speedup (5-8x faster)"
  ensure
    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir)
  end
end

if __FILE__ == $0
  begin
    require "benchmark/ips"
  rescue LoadError
    puts "ERROR: benchmark-ips gem is required for this benchmark"
    puts "Install it with: gem install benchmark-ips"
    exit 1
  end

  component_count = (ARGV[0] || 20).to_i
  run_speed_benchmark(component_count: component_count)
end

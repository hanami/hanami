#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "fileutils"
require "benchmark/ips"

# Load local Hanami development version
require_relative "../lib/hanami"

def create_simple_app(temp_dir)
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

    module SimpleApp
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

  # Create minimal action classes
  minimal_action_code = <<~RUBY
    def initialize
      # Minimal initialization - just enough to show object creation overhead
      # @created_at = Time.now.to_f
      # @name = "Hanami"
      # @number = 123
      # @data = Data.define.new
    end

    def call(env = {})
      { status: 200, created_at: @created_at, object_id: object_id }
    end
  RUBY

  File.write("#{temp_dir}/slices/memoized/actions/simple_action.rb", <<~RUBY)
    module Memoized
      module Actions
        class SimpleAction
          #{minimal_action_code}
        end
      end
    end
  RUBY

  File.write("#{temp_dir}/slices/normal/actions/simple_action.rb", <<~RUBY)
    module Normal
      module Actions
        class SimpleAction
          #{minimal_action_code}
        end
      end
    end
  RUBY

  # Create minimal view classes
  minimal_view_code = <<~RUBY
    def initialize
      # Minimal initialization - just enough to show object creation overhead
      # @created_at = Time.now.to_f
      # @name = "Hanami"
      # @number = 123
      # @data = Data.define.new
    end

    def render(data = {})
      { view: "simple", created_at: @created_at, object_id: object_id, data: data }
    end
  RUBY

  File.write("#{temp_dir}/slices/memoized/views/simple_view.rb", <<~RUBY)
    module Memoized
      module Views
        class SimpleView
          #{minimal_view_code}
        end
      end
    end
  RUBY

  File.write("#{temp_dir}/slices/normal/views/simple_view.rb", <<~RUBY)
    module Normal
      module Views
        class SimpleView
          #{minimal_view_code}
        end
      end
    end
  RUBY

  temp_dir
end

def run_simple_benchmark
  temp_dir = Dir.mktmpdir("hanami_simple_benchmark")

  begin
    puts "Creating minimal Hanami application for microbenchmark..."
    create_simple_app(temp_dir)

    # Change to temp directory
    original_dir = Dir.pwd
    Dir.chdir(temp_dir)

    # Load the app
    require "./config/app"
    require "hanami/prepare"

    puts "Simple Hanami application loaded!"
    puts
    puts "Configuration verification:"
    puts "Memoized slice memoize_component_dirs: #{Memoized::Slice.config.memoize_component_dirs}"
    puts "Normal slice memoize_component_dirs: #{Normal::Slice.config.memoize_component_dirs}"
    puts

    # Test memoization behavior
    puts "Testing memoization behavior:"

    # Actions
    action1 = Memoized::Slice["actions.simple_action"]
    action2 = Memoized::Slice["actions.simple_action"]
    puts "Memoized Actions - same instance: #{action1.object_id == action2.object_id}"

    action3 = Normal::Slice["actions.simple_action"]
    action4 = Normal::Slice["actions.simple_action"]
    puts "Normal Actions - same instance: #{action3.object_id == action4.object_id}"

    # Views
    view1 = Memoized::Slice["views.simple_view"]
    view2 = Memoized::Slice["views.simple_view"]
    puts "Memoized Views - same instance: #{view1.object_id == view2.object_id}"

    view3 = Normal::Slice["views.simple_view"]
    view4 = Normal::Slice["views.simple_view"]
    puts "Normal Views - same instance: #{view3.object_id == view4.object_id}"
    puts

    # Microbenchmark Actions
    puts "=== SIMPLE ACTION MICROBENCHMARK ==="
    puts "Measuring minimal component resolution overhead:"

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      x.report("Memoized Actions") do
        Memoized::Slice["actions.simple_action"]
      end

      x.report("Normal Actions") do
        Normal::Slice["actions.simple_action"]
      end

      x.compare!
    end

    puts "\n" + "=" * 60

    # Microbenchmark Views
    puts "=== SIMPLE VIEW MICROBENCHMARK ==="
    puts "Measuring minimal component resolution overhead:"

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      x.report("Memoized Views") do
        Memoized::Slice["views.simple_view"]
      end

      x.report("Normal Views") do
        Normal::Slice["views.simple_view"]
      end

      x.compare!
    end
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

  run_simple_benchmark
end
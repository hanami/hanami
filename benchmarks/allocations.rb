#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "fileutils"
require_relative "../lib/hanami"

class AllocationsBenchmark
  RESOLUTION_COUNTS = [100, 1_000, 5_000, 10_000].freeze
  LABEL_WIDTH = 12
  COL_WIDTH = 24

  def initialize(component_count:)
    @component_count = component_count
    freeze
  end

  def call
    app_label = @component_count <= 50 ? "SMALL" : "LARGE"
    puts "=== HANAMI ALLOCATIONS BENCHMARK (#{app_label} APP) ==="
    puts "#{@component_count} actions + #{@component_count} views"
    puts
    RESOLUTION_COUNTS.each { |n| run_test(resolutions: n) }
  end

  private

  def run_test(resolutions:)
    puts "=" * 60
    puts "TEST: #{@component_count * 2} components resolved #{resolutions} times"
    puts "=" * 60
    puts
    results = measure_all(resolutions: resolutions)
    print_results(results: results)
  end

  def measure_all(resolutions:)
    {}.tap do |hash|
      [:memoized, :normal].each do |key|
        print "Measuring #{key}... "
        hash[key] = measure(memoize: key == :memoized, resolutions: resolutions)
        puts "Done"
      end
    end
  end

  def print_results(results:)
    puts
    normal = results[:normal][:delta]
    memoized = results[:memoized][:delta]
    saved = normal - memoized
    pct = normal.positive? ? "#{((saved.to_f / normal) * 100).round(1)}%" : "n/a"

    puts "#{"Normal:".ljust(LABEL_WIDTH)}#{fmt(normal).rjust(COL_WIDTH)}"
    puts "#{"Memoized:".ljust(LABEL_WIDTH)}#{fmt(memoized).rjust(COL_WIDTH)}"
    puts
    puts "#{"Saved:".ljust(LABEL_WIDTH)}#{("#{fmt(saved)} (#{pct})").rjust(COL_WIDTH)}"
    puts
  end

  def measure(memoize:, resolutions:)
    temp_dir = Dir.mktmpdir("hanami_alloc_benchmark")

    begin
      create_app(temp_dir, memoize: memoize)
      run_measurement_script(temp_dir, resolutions: resolutions)
    ensure
      FileUtils.rm_rf(temp_dir)
    end
  end

  def create_app(temp_dir, memoize:)
    FileUtils.mkdir_p("#{temp_dir}/config/slices")
    FileUtils.mkdir_p("#{temp_dir}/slices/main/actions")
    FileUtils.mkdir_p("#{temp_dir}/slices/main/views")
    write_app_config(temp_dir)
    write_slice_config(temp_dir, memoize: memoize)
    write_components(temp_dir)
  end

  def write_app_config(temp_dir)
    File.write("#{temp_dir}/config/app.rb", <<~RUBY)
      require "hanami"

      module AllocApp
        class App < Hanami::App
          config.root = "#{temp_dir}"
          config.logger.stream = StringIO.new
        end
      end
    RUBY
  end

  def write_slice_config(temp_dir, memoize:)
    no_memoize_line = memoize ? "" : "config.no_memoize = ->(_component) { true }"

    File.write("#{temp_dir}/config/slices/main.rb", <<~RUBY)
      module Main
        class Slice < Hanami::Slice
          #{no_memoize_line}
        end
      end
    RUBY
  end

  def write_components(temp_dir)
    @component_count.times do |i|
      write_action(temp_dir, i)
      write_view(temp_dir, i)
    end
  end

  def write_action(temp_dir, i)
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
          end
        end
      end
    RUBY
  end

  def write_view(temp_dir, i)
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
          end
        end
      end
    RUBY
  end

  def run_measurement_script(temp_dir, resolutions:)
    script_path = write_measurement_script(temp_dir, resolutions: resolutions)
    output = execute_script(script_path)

    if output.strip.empty?
      warn "Warning: measurement failed"
      return {before: 0, after: 0, delta: 0}
    end

    before, after = output.strip.split(",").map(&:to_i)
    {before: before, after: after, delta: after - before}
  end

  def write_measurement_script(temp_dir, resolutions:)
    script_path = "#{temp_dir}/measure.rb"
    File.write(script_path, <<~RUBY)
      Dir.chdir("#{temp_dir}")
      require "./config/app"
      require "hanami/prepare"

      GC.start
      GC.disable

      before = GC.stat[:total_allocated_objects]

      #{resolutions}.times do
        #{@component_count}.times do |i|
          Main::Slice["actions.action_\#{i}"]
          Main::Slice["views.view_\#{i}"]
        end
      end

      after = GC.stat[:total_allocated_objects]
      GC.enable

      puts "\#{before},\#{after}"
    RUBY
    script_path
  end

  def execute_script(script_path)
    rubylib = File.expand_path("../lib", __dir__)
    hanami_root = File.expand_path("..", __dir__)
    `cd "#{hanami_root}" && RUBYLIB="#{rubylib}" bundle exec ruby "#{script_path}" 2>/dev/null`
  end

  def fmt(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse
  end
end

if $PROGRAM_NAME == __FILE__
  component_count = (ARGV[0] || 20).to_i
  AllocationsBenchmark.new(component_count: component_count).call
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require "tempfile"
require "fileutils"
require "benchmark/ips"
require_relative "../lib/hanami"

class SpeedBenchmark
  SEPARATOR = "=" * 60
  DEFAULT_COMPONENT_COUNT = 20

  def initialize(component_count:)
    @component_count = component_count
    @temp_dir = Dir.mktmpdir("hanami_speed_benchmark")
    freeze
  end

  def call
    create_app
    load_app
    print_verification
    run_single_benchmark
    run_random_benchmark
    run_sequential_benchmark
  ensure
    FileUtils.rm_rf(@temp_dir)
  end

  private

  def app_label
    @component_count <= 50 ? "SMALL" : "LARGE"
  end

  def create_app
    FileUtils.mkdir_p("#{@temp_dir}/config/slices")
    FileUtils.mkdir_p("#{@temp_dir}/slices/memoized/actions")
    FileUtils.mkdir_p("#{@temp_dir}/slices/memoized/views")
    FileUtils.mkdir_p("#{@temp_dir}/slices/normal/actions")
    FileUtils.mkdir_p("#{@temp_dir}/slices/normal/views")
    write_app_config
    write_slice_configs
    write_components
  end

  def write_app_config
    File.write("#{@temp_dir}/config/app.rb", <<~RUBY)
      require "hanami"

      module SpeedApp
        class App < Hanami::App
          config.root = "#{@temp_dir}"
          config.logger.stream = StringIO.new
        end
      end
    RUBY
  end

  def write_slice_configs
    File.write("#{@temp_dir}/config/slices/memoized.rb", <<~RUBY)
      module Memoized
        class Slice < Hanami::Slice
        end
      end
    RUBY

    File.write("#{@temp_dir}/config/slices/normal.rb", <<~RUBY)
      module Normal
        class Slice < Hanami::Slice
          config.no_memoize = ->(_component) { true }
        end
      end
    RUBY
  end

  def write_components
    @component_count.times do |i|
      write_action(i)
      write_view(i)
    end
  end

  def action_body(i)
    <<~RUBY
      def initialize
        @created_at = Time.now.to_f
        @name = "Action#{i}"
        @data = { key: "value" * 10 }
        @array = Array.new(100) { |j| j }
      end
    RUBY
  end

  def view_body(i)
    <<~RUBY
      def initialize
        @created_at = Time.now.to_f
        @name = "View#{i}"
        @data = { key: "value" * 10 }
        @array = Array.new(100) { |j| j }
      end
    RUBY
  end

  def write_action(i)
    File.write("#{@temp_dir}/slices/memoized/actions/action_#{i}.rb", <<~RUBY)
      module Memoized
        module Actions
          class Action#{i}
            #{action_body(i)}
          end
        end
      end
    RUBY

    File.write("#{@temp_dir}/slices/normal/actions/action_#{i}.rb", <<~RUBY)
      module Normal
        module Actions
          class Action#{i}
            #{action_body(i)}
          end
        end
      end
    RUBY
  end

  def write_view(i)
    File.write("#{@temp_dir}/slices/memoized/views/view_#{i}.rb", <<~RUBY)
      module Memoized
        module Views
          class View#{i}
            #{view_body(i)}
          end
        end
      end
    RUBY

    File.write("#{@temp_dir}/slices/normal/views/view_#{i}.rb", <<~RUBY)
      module Normal
        module Views
          class View#{i}
            #{view_body(i)}
          end
        end
      end
    RUBY
  end

  def load_app
    puts "=== HANAMI SPEED BENCHMARK (#{app_label} APP) ==="
    puts "#{@component_count} actions + #{@component_count} views per slice"
    Dir.chdir(@temp_dir)
    require "./config/app"
    require "hanami/prepare"
    puts "App loaded!"
  end

  def print_verification
    puts
    print_config_verification
    puts
    print_instance_verification
    puts
  end

  def print_config_verification
    puts "Memoized slice no_memoize: #{Memoized::Slice.config.no_memoize.inspect}"
    puts "Normal slice no_memoize:   #{Normal::Slice.config.no_memoize.inspect}"
  end

  def print_instance_verification
    puts "Memoized actions - same instance: #{Memoized::Slice["actions.action_0"].equal?(Memoized::Slice["actions.action_0"])}"
    puts "Normal actions   - same instance: #{Normal::Slice["actions.action_0"].equal?(Normal::Slice["actions.action_0"])}"
    puts "Memoized views   - same instance: #{Memoized::Slice["views.view_0"].equal?(Memoized::Slice["views.view_0"])}"
    puts "Normal views     - same instance: #{Normal::Slice["views.view_0"].equal?(Normal::Slice["views.view_0"])}"
  end

  def run_single_benchmark
    puts SEPARATOR
    puts "=== SINGLE COMPONENT RESOLUTION ==="
    puts "Resolving the same action repeatedly"
    puts SEPARATOR

    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)
      x.report("Normal")   { Normal::Slice["actions.action_0"] }
      x.report("Memoized") { Memoized::Slice["actions.action_0"] }
      x.compare!
    end

    puts
  end

  def run_random_benchmark
    puts SEPARATOR
    puts "=== RANDOM COMPONENT RESOLUTION ==="
    puts "Resolving random actions from pool of #{@component_count}"
    puts SEPARATOR

    count = @component_count
    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)
      x.report("Normal")   { Normal::Slice["actions.action_#{rand(count)}"] }
      x.report("Memoized") { Memoized::Slice["actions.action_#{rand(count)}"] }
      x.compare!
    end

    puts
  end

  def run_sequential_benchmark
    puts SEPARATOR
    puts "=== SEQUENTIAL COMPONENT RESOLUTION ==="
    puts "Resolving all #{@component_count} actions in sequence"
    puts SEPARATOR

    count = @component_count
    Benchmark.ips do |x|
      x.config(time: 3, warmup: 1)

      normal_i = 0
      x.report("Normal") do
        Normal::Slice["actions.action_#{normal_i % count}"]
        normal_i += 1
      end

      memoized_i = 0
      x.report("Memoized") do
        Memoized::Slice["actions.action_#{memoized_i % count}"]
        memoized_i += 1
      end

      x.compare!
    end
  end
end

if $PROGRAM_NAME == __FILE__
  component_count = (ARGV[0] || SpeedBenchmark::DEFAULT_COMPONENT_COUNT).to_i
  SpeedBenchmark.new(component_count: component_count).call
end

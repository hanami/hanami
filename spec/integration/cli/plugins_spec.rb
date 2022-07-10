# frozen_string_literal: true

require "pathname"

RSpec.describe "CLI plugins", type: :integration do
  xit "includes its commands in CLI output" do
    with_project do
      bundle_exec "hanami"
      expect(out).to include("hanami plugin [SUBCOMMAND]")
    end
  end

  xit "executes command from plugin" do
    with_project do
      bundle_exec "hanami plugin version"
      expect(out).to include("v0.1.0")
    end
  end

  # See https://github.com/hanami/hanami/issues/838
  it "guarantees 'hanami new' to generate a project" do
    project = "bookshelf_without_gemfile"

    with_system_tmp_directory do
      run_cmd_with_clean_env "hanami new #{project}"
      destination = Pathname.new(Dir.pwd).join(project)

      expect(destination).to exist
    end
  end

  private

  def with_project(&block)
    super("bookshelf", gems: {"hanami-plugin" => {groups: [:plugins], path: Pathname.new(__dir__).join("..", "..", "..", "spec", "support", "fixtures", "hanami-plugin").realpath.to_s}}, &block)
  end
end

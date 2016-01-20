require 'integration_helper'

describe 'Rake tasks (Application)' do
  before do
    public_directory.mkpath
    assets_directory.rmtree if assets_directory.exist?

    manifest = public_directory.join('assets.json')
    manifest.delete if manifest.exist?

    @current_dir = Dir.pwd
    Dir.chdir root
  end

  after do
    Dir.chdir @current_dir
    @current_dir = nil
  end

  let(:root)             { FIXTURES_ROOT.join('rake', 'rake_tasks_app') }
  let(:public_directory) { root.join('public') }
  let(:assets_directory) { public_directory.join('assets') }

  describe "task preload" do
    it "is listed with rake -T" do
      out = `bundle exec rake -T`
      out.must_include %(rake preload      # Preload project configuration)
    end

    it "preloads configuration" do
      out = `bundle exec rake preloading:print_env`

      out.must_include %("RAKE_TASKS_APP_DATABASE_URL"=>"sqlite://)
      out.must_include %("SERVE_STATIC_ASSETS"=>"true")
      out.must_include %("RAKE_TASKS_APP_SESSIONS_SECRET")
      out.must_include %("RACK_ENV")
      out.must_include %("HANAMI_ENV")
      out.must_include %("HANAMI_HOST")
      out.must_include %("HANAMI_PORT"=>"2300")
    end

    it "doesn't load application code from lib/" do
      out = `bundle exec rake preloading:assert_defined_entity`
      out.must_equal "defined: \n"
    end

    it "doesn't load application code from apps/" do
      out = `bundle exec rake preloading:assert_defined_action`
      out.must_equal "defined: \n"
    end
  end

  describe "task environment" do
    it "is listed with rake -T" do
      out = `bundle exec rake -T`
      out.must_include %(rake environment  # Load the full project)
    end

    it "preloads configuration" do
      out = `bundle exec rake full:print_env`

      out.must_include %("RAKE_TASKS_APP_DATABASE_URL"=>"sqlite://)
      out.must_include %("SERVE_STATIC_ASSETS"=>"true")
      out.must_include %("RAKE_TASKS_APP_SESSIONS_SECRET")
      out.must_include %("RACK_ENV")
      out.must_include %("HANAMI_ENV")
      out.must_include %("HANAMI_HOST")
      out.must_include %("HANAMI_PORT"=>"2300")
    end

    it "loads application code from lib/" do
      out = `bundle exec rake full:assert_defined_entity`
      out.must_equal "defined: constant\n"
    end

    it "loads application code from apps/" do
      out = `bundle exec rake full:assert_defined_action`
      out.must_equal "defined: constant\n"
    end
  end

  describe "task db:migrate" do
    before do
      root.join('db').children.each do |child|
        next unless child.to_s.match(/\.sqlite\z/)
        child.delete
      end
    end

    it "isn't listed with rake -T" do
      out = `bundle exec rake -T`
      out.wont_include %(rake db:migrate)
    end

    it "migrates the database" do
      success = system "bundle exec rake db:migrate"
      success.must_equal true

      out = `bundle exec rake database:inspect`
      out.must_include "OK"
    end
  end

  describe "task assets:precompile" do
    before do
      root.join('public').children.each do |child|
        child.delete
      end
    end

    it "isn't listed with rake -T" do
      out = `bundle exec rake -T`
      out.wont_include %(rake assets:precompile)
    end

    it "precompile assets" do
      success = system "bundle exec rake assets:precompile"
      success.must_equal true

      root.join('public', 'assets.json').must_be :exist?
    end
  end
end

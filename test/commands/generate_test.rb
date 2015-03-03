require 'test_helper'
require 'lotus/cli'
require 'lotus/commands/generate'

describe Lotus::Commands::Generate do
  let(:opts)     { Hash.new }
  let(:env)      { Lotus::Environment.new(opts) }
  let(:command)  { Lotus::Commands::Generate.new(target, app_name, target_name, env, cli) }
  let(:cli)      { Lotus::Cli.new }
  let(:app_name) { 'web' }

  def create_temporary_dir
    tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/generators/generate')
    tmp.rmtree if tmp.exist?
    tmp.mkpath

    tmp.join('apps', app_name).mkpath

    Dir.chdir(tmp)
    @root = tmp
  end

  def chdir_to_root
    Dir.chdir(@pwd)
  end

  before do
    create_temporary_dir
  end

  after do
    chdir_to_root
  end

  describe 'action' do
    let(:target)      { :action }
    let(:target_name) { 'dashboard#index' }

    before do
      capture_io { command.start }
    end

    describe 'apps/web/controllers/dashboard/index.rb' do
      it 'generates it' do
        content = @root.join('apps/web/controllers/dashboard/index.rb').read
        content.must_match %(module Web::Controllers::Dashboard)
        content.must_match %(  class Index)
        content.must_match %(    include Web::Action)
        content.must_match %(    def call(params))
      end
    end

    describe 'spec/web/controllers/dashboard/index_spec.rb' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(describe Web::Controllers::Dashboard::Index do)
          content.must_match %(  before do)
          content.must_match %(    @action = Web::Controllers::Dashboard::Index.new)
          content.must_match %(  end)
          content.must_match %(  it "is successful" do)
          content.must_match %(    response = @action.call({}))
          content.must_match %(    response[0].must_equal 200)
        end
      end

      describe 'rspec' do
        let(:opts) { Hash[test: 'rspec'] }

        it 'generates it' do
          content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(describe Web::Controllers::Dashboard::Index do)
          content.must_match %(  before do)
          content.must_match %(    @action = Web::Controllers::Dashboard::Index.new)
          content.must_match %(  end)
          content.must_match %(  it "is successful" do)
          content.must_match %(    response = @action.call({}))
          content.must_match %(    expect(response[0]).to eq 200)
        end
      end
    end

    describe 'apps/web/views/dashboard/index.rb' do
      it 'generates it' do
        content = @root.join('apps/web/views/dashboard/index.rb').read
        content.must_match %(module Web::Views::Dashboard)
        content.must_match %(  class Index)
        content.must_match %(    include Web::View)
      end
    end

    describe 'spec/web/views/dashboard/index_spec.rb' do
      describe 'minitest (default)' do
        it 'generates it' do
          content = @root.join('spec/web/views/dashboard/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(describe Web::Views::Dashboard::Index do)
          content.must_match %(  before do)
          content.must_match %(    @template = Lotus::View::Template.new('apps/web/templates/dashboard/index.html.erb'))
          content.must_match %(    @view     = Web::Views::Dashboard::Index.new(@template, {foo: 'bar'}))
          content.must_match %(  end)
          content.must_match %(  it "exposes #foo" do)
          content.must_match %(    @view.foo.must_equal 'bar')
          content.must_match %(  end)
        end
      end

      describe 'rspec' do
        let(:opts) { Hash[test: 'rspec'] }

        it 'generates it' do
          content = @root.join('spec/web/views/dashboard/index_spec.rb').read
          content.must_match %(require 'spec_helper')
          content.must_match %(describe Web::Views::Dashboard::Index do)
          content.must_match %(  before do)
          content.must_match %(    @template = Lotus::View::Template.new('apps/web/templates/dashboard/index.html.erb'))
          content.must_match %(    @view     = Web::Views::Dashboard::Index.new(@template, {foo: 'bar'}))
          content.must_match %(  end)
          content.must_match %(  it "exposes #foo" do)
          content.must_match %(    expect(@view.foo).to eq 'bar')
          content.must_match %(  end)
        end
      end
    end

    describe 'apps/web/templates/dashboard/index.html.erb' do
      it 'generates it' do
        content = @root.join('apps/web/templates/dashboard/index.html.erb').read
        content.must_be :empty?
      end
    end
  end
end

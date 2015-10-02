require 'test_helper'
require 'sequel'
require 'fileutils'

describe 'lotus db' do
  ARCHITECTURES = %w(container app)

  def create_temporary_dir
    @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/integration/cli/database')
    FileUtils.rm_rf(@tmp)
    @tmp.mkpath

    Dir.chdir(@tmp)
  end

  def generate_application
    @app_name = 'delivery'
    `bundle exec lotus new #{ @app_name } --architecture="#{ architecture }" --database=sqlite3`
    Dir.chdir(@root = @tmp.join(@app_name))

    File.open(@root.join('.env.development'), 'w') do |f|
      f.write <<-DOTENV
#{ @app_name.upcase }_DATABASE_URL="sqlite://#{ @root.join("db/#{ @app_name }_development.sqlite3") }"
      DOTENV
    end

    File.open(@root.join('.env.test'), 'w') do |f|
      f.write <<-DOTENV
#{ @app_name.upcase }_DATABASE_URL="sqlite://#{ @root.join("db/#{ @app_name }_test.sqlite3") }"
      DOTENV
    end

    File.open(@root.join('.env'), 'w') do |f|
      f.write <<-DOTENV
#{ @app_name.upcase }_DATABASE_URL="sqlite://#{ @root.join("db/#{ @app_name }.sqlite3") }"
      DOTENV
    end

    File.open(@root.join('db/migrations/20150613152241_create_users.rb'), 'w') do |f|
      f.write <<-MIGRATION
Lotus::Model.migration do
  change do
    create_table :users do
      primary_key :id
      column :email, String
    end
  end
end
MIGRATION
    end

    File.open(@root.join('db/migrations/20150613152815_add_name_to_users.rb'), 'w') do |f|
      f.write <<-MIGRATION
Lotus::Model.migration do
  change do
    alter_table :users do
      add_column :name, String
    end
  end
end
MIGRATION
    end

  end

  def db_create
    `LOTUS_ENV="#{ lotus_env }" bundle exec lotus db create`
  end

  def db_drop
    `LOTUS_ENV="#{ lotus_env }" bundle exec lotus db drop`
  end

  def db_migrate(version = nil)
    `LOTUS_ENV="#{ lotus_env }" bundle exec lotus db migrate #{ version }`
  end

  def db_apply
    `LOTUS_ENV="#{ lotus_env }" bundle exec lotus db apply`
  end

  def db_prepare
    `LOTUS_ENV="#{ lotus_env }" bundle exec lotus db prepare`
  end

  def db_version
    `LOTUS_ENV="#{ lotus_env }" bundle exec lotus db version`
  end

  def chdir_to_root
    Dir.chdir($pwd)
  end

  before do
    create_temporary_dir
    generate_application
  end

  after do
    chdir_to_root
  end

  let(:lotus_env) { 'development' }

  describe 'create' do
    before do
      db_create
    end

    ARCHITECTURES.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'creates database' do
            @root.join("db/#{ @app_name }_development.sqlite3").must_be :exist?
          end
        end

        describe 'test environment' do
          let(:lotus_env) { 'test' }

          it 'creates database' do
            @root.join("db/#{ @app_name }_test.sqlite3").must_be :exist?
          end
        end

        describe 'production environment' do
          let(:lotus_env) { 'production' }

          it "doesn't create database" do
            @root.join("db/#{ @app_name }.sqlite3").wont_be :exist?
          end
        end
      end
    end
  end

  describe 'drop' do
    before do
      # simulate pre-existing production database
      FileUtils.touch @root.join("db/#{ @app_name }.sqlite3")

      db_create
      db_drop
    end

    ARCHITECTURES.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'drops database' do
            @root.join("db/#{ @app_name }_development.sqlite3").wont_be :exist?
          end
        end

        describe 'test environment' do
          let(:lotus_env) { 'test' }

          it 'drops database' do
            @root.join("db/#{ @app_name }_test.sqlite3").wont_be :exist?
          end
        end

        describe 'production environment' do
          let(:lotus_env) { 'production' }

          it "doesn't drop database" do
            @root.join("db/#{ @app_name }.sqlite3").must_be :exist?
          end
        end
      end
    end
  end

  describe 'migrate' do
    before do
      db_create
      db_migrate
    end

    ARCHITECTURES.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'migrates database' do
            database   = @root.join("db/#{ @app_name }_development.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'
          end
        end

        describe 'test environment' do
          let(:lotus_env) { 'test' }

          it 'migrates database' do
            database   = @root.join("db/#{ @app_name }_test.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'
          end
        end

        describe 'production environment' do
          let(:lotus_env) { 'production' }

          it 'migrates database'
          # it 'migrates database' do
          #   database   = @root.join("db/#{ @app_name }.sqlite3")
          #   connection = Sequel.connect("sqlite://#{ database }")
          #   version    = connection[:schema_migrations].to_a.last

          #   version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'
          # end
        end
      end
    end
  end

  describe 'migrate with version' do
    before do
      db_create
      db_migrate
      db_migrate "20150613152241"
    end

    ARCHITECTURES.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'migrates database' do
            database   = @root.join("db/#{ @app_name }_development.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152241_create_users.rb'
          end
        end

        describe 'test environment' do
          let(:lotus_env) { 'test' }

          it 'migrates database' do
            database   = @root.join("db/#{ @app_name }_test.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152241_create_users.rb'
          end
        end

        describe 'production environment' do
          let(:lotus_env) { 'production' }

          it 'migrates database'
          # it 'migrates database' do
          #   database   = @root.join("db/#{ @app_name }.sqlite3")
          #   connection = Sequel.connect("sqlite://#{ database }")
          #   version    = connection[:schema_migrations].to_a.last

          #   version.fetch(:filename).must_equal '20150613152241_create_users.rb'
          # end
        end
      end
    end
  end

  describe 'apply' do
    before do
      @root.join("db/schema.sql").delete

      db_create
      db_apply
    end

    ARCHITECTURES.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'migrates database' do
            database   = @root.join("db/#{ @app_name }_development.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'
          end

          it 'generates schema.sql' do
            @root.join("db/schema.sql").must_be :exist?
          end

          it 'deletes migrations' do
            @root.join("db/migrations").children.must_be :empty?
          end
        end

        describe 'test environment' do
          let(:lotus_env) { 'test' }

          it "doesn't migrate database" do
            database   = @root.join("db/#{ @app_name }_test.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")

            connection.tables.must_be :empty?
          end

          it "doesn't generate schema.sql" do
            @root.join("db/schema.sql").wont_be :exist?
          end

          it "doesn't delete migrations" do
            @root.join("db/migrations").children.wont_be :empty?
          end
        end

        describe 'production environment' do
          let(:lotus_env) { 'production' }

          it "doesn't migrate database" do
            database   = @root.join("db/#{ @app_name }.sqlite3")
            connection = Sequel.connect("sqlite://#{ database }")

            connection.tables.must_be :empty?
          end

          it "doesn't generate schema.sql" do
            @root.join("db/schema.sql").wont_be :exist?
          end

          it "doesn't delete migrations" do
            @root.join("db/migrations").children.wont_be :empty?
          end
        end
      end
    end
  end

  describe 'prepare' do
    before do
      db_create
      db_apply
      db_drop

      File.open(@root.join('db/migrations/20150613154832_create_deliveries.rb'), 'w') do |f|
        f.write <<-MIGRATION
Lotus::Model.migration do
  change do
    create_table :deliveries do
      primary_key :id
      foreign_key :user_id, :users
    end
  end
end
MIGRATION
      end

      db_prepare
    end

    let(:architecture) { 'container' }

    describe 'default environment' do
      it 'creates and migrates database' do
        database   = @root.join("db/#{ @app_name }_development.sqlite3")
        connection = Sequel.connect("sqlite://#{ database }")
        version    = connection[:schema_migrations].to_a.last

        version.fetch(:filename).must_equal '20150613154832_create_deliveries.rb'
      end
    end

    describe 'test environment' do
      let(:lotus_env) { 'test' }

      it 'creates and migrates database' do
        database   = @root.join("db/#{ @app_name }_test.sqlite3")
        connection = Sequel.connect("sqlite://#{ database }")
        version    = connection[:schema_migrations].to_a.last

        version.fetch(:filename).must_equal '20150613154832_create_deliveries.rb'
      end
    end

    describe 'production environment' do
      let(:lotus_env) { 'production' }

      it "doesn't create database" do
        database   = @root.join("db/#{ @app_name }.sqlite3")
        connection = Sequel.connect("sqlite://#{ database }")

        connection.tables.must_be :empty?
      end
    end
  end

  describe 'version' do
    before do
      db_create
      db_migrate
    end

    ARCHITECTURES.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'prints current database version' do
            out = db_version

            out.must_equal "20150613152815\n"
          end
        end

        describe 'test environment' do
          let(:lotus_env) { 'test' }

          it 'prints current database version' do
            out = db_version

            out.must_equal "20150613152815\n"
          end
        end

        describe 'production environment' do
          let(:lotus_env) { 'production' }

          it 'prints current database version'
          # it 'prints current database version' do
          #   out = db_version

          #   out.must_equal "20150613152815\n"
          # end
        end
      end
    end
  end
end

require 'test_helper'
require 'sequel'
require 'fileutils'

describe 'hanami db' do
  let(:adapter_prefix) { 'jdbc:' if Hanami::Utils.jruby? }

  architectures = {
    container: nil,
    app: nil
  }

  let(:hanami_env) { 'development' }
  let(:app_name) { 'delivery' }
  let(:tmp) { Pathname.new(Dir.pwd).join("tmp/integration/cli/database/#{ architecture }") }
  let(:root) { tmp.join(app_name) }

  def create_temporary_dir
    FileUtils.rm_rf(tmp)
    tmp.mkpath

    Dir.chdir(tmp)
  end

  def generate_application
    `hanami new #{ app_name } --architecture="#{ architecture }" --database=sqlite3`
    Dir.chdir(root)

    File.open(root.join('.env.development'), 'w') do |f|
      f.write <<-DOTENV
DATABASE_URL="#{ adapter_prefix }sqlite://#{ root.join("db/#{ app_name }_development.sqlite3") }"
      DOTENV
    end

    File.open(root.join('.env.test'), 'w') do |f|
      f.write <<-DOTENV
DATABASE_URL="#{ adapter_prefix }sqlite://#{ root.join("db/#{ app_name }_test.sqlite3") }"
      DOTENV
    end

    File.open(root.join('.env.production'), 'w') do |f|
      f.write <<-DOTENV
DATABASE_URL="#{ adapter_prefix }sqlite://#{ root.join("db/#{ app_name }.sqlite3") }"
      DOTENV
    end

    write_migrations
  end

  def write_migrations
    File.open(root.join('db/migrations/20150613152241_create_users.rb'), 'w') do |f|
      f.write <<-MIGRATION
Hanami::Model.migration do
  change do
    create_table :users do
      primary_key :id
      column :email, String
    end
  end
end
MIGRATION
    end

    File.open(root.join('db/migrations/20150613152815_add_name_to_users.rb'), 'w') do |f|
      f.write <<-MIGRATION
Hanami::Model.migration do
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
    `HANAMI_ENV="#{ hanami_env }" hanami db create`
  end

  def db_drop
    `HANAMI_ENV="#{ hanami_env }" hanami db drop`
  end

  def db_migrate(version = nil)
    `HANAMI_ENV="#{ hanami_env }" hanami db migrate #{ version }`
  end

  def db_apply
    `HANAMI_ENV="#{ hanami_env }" hanami db apply`
  end

  def db_prepare
    `HANAMI_ENV="#{ hanami_env }" hanami db prepare`
  end

  def db_version
    `HANAMI_ENV="#{ hanami_env }" hanami db version`
  end

  before do
    unless architectures[architecture]
      architectures[architecture] = begin
                                      create_temporary_dir
                                      generate_application

                                      true
                                    end
    end

    Dir.chdir(root)
    FileUtils.rm_rf(Dir.glob(root.join('db/*.sqlite3').to_s))
  end

  after do
    Dir.chdir($pwd)
    FileUtils.rm_rf(Dir.glob(root.join('db/*.sqlite3').to_s))
  end

  describe 'create' do
    before { db_create }

    architectures.keys.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'creates database' do
            root.join("db/#{ app_name }_development.sqlite3").must_be :exist?
          end
        end

        describe 'test environment' do
          let(:hanami_env) { 'test' }

          it 'creates database' do
            root.join("db/#{ app_name }_test.sqlite3").must_be :exist?
          end
        end

        describe 'production environment' do
          let(:hanami_env) { 'production' }

          it "doesn't create database" do
            root.join("db/#{ app_name }.sqlite3").wont_be :exist?
          end
        end
      end
    end
  end

  describe 'drop' do
    architectures.keys.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'drops database' do
            db_create
            db_drop

            root.join("db/#{ app_name }_development.sqlite3").wont_be :exist?
          end
        end

        describe 'test environment' do
          let(:hanami_env) { 'test' }

          it 'drops database' do
            db_create
            db_drop

            root.join("db/#{ app_name }_test.sqlite3").wont_be :exist?
          end
        end

        describe 'production environment' do
          let(:hanami_env) { 'production' }

          it "doesn't drop database" do
            production_database = root.join("db/#{ app_name }.sqlite3")
            FileUtils.touch production_database

            root.join("db/#{ app_name }.sqlite3").must_be :exist?

            FileUtils.rm_rf(production_database)
          end
        end
      end
    end
  end

  describe 'migrate' do
    before do
      db_create
      write_migrations
      db_migrate
    end

    architectures.keys.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'migrates database' do
            database   = root.join("db/#{ app_name }_development.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'
          end
        end

        describe 'test environment' do
          let(:hanami_env) { 'test' }

          it 'migrates database' do
            database   = root.join("db/#{ app_name }_test.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'
          end
        end

        describe 'production environment' do
          let(:hanami_env) { 'production' }

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
      write_migrations
      db_migrate
      db_migrate '20150613152241'
    end

    architectures.keys.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'migrates database' do
            database   = root.join("db/#{ app_name }_development.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152241_create_users.rb'
          end
        end

        describe 'test environment' do
          let(:hanami_env) { 'test' }

          it 'migrates database' do
            database   = root.join("db/#{ app_name }_test.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152241_create_users.rb'
          end
        end

        describe 'production environment' do
          let(:hanami_env) { 'production' }

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
      FileUtils.rm_rf(root.join('db/schema.sql'))
      write_migrations

      db_create
      db_apply
    end

    after { write_migrations }

    architectures.keys.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'migrates database generating schema and deleting migrations' do
            database   = root.join("db/#{ app_name }_development.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
            version    = connection[:schema_migrations].to_a.last

            version.fetch(:filename).must_equal '20150613152815_add_name_to_users.rb'

            root.join("db/schema.sql").must_be :exist?
            root.join("db/migrations").children.must_be :empty?
          end
        end

        describe 'test environment' do
          let(:hanami_env) { 'test' }

          it "doesn't migrate database without generating schema neither deleting migrations" do
            database   = root.join("db/#{ app_name }_test.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")

            connection.tables.must_be :empty?

            root.join("db/schema.sql").wont_be :exist?
            root.join("db/migrations").children.wont_be :empty?
          end
        end

        describe 'production environment' do
          let(:hanami_env) { 'production' }

          it "doesn't migrate database without generating schema neither deleting migrations" do
            database   = root.join("db/#{ app_name }.sqlite3")
            connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")

            connection.tables.must_be :empty?

            root.join("db/schema.sql").wont_be :exist?
            root.join("db/migrations").children.wont_be :empty?
          end
        end
      end
    end
  end

  describe 'prepare' do
    let(:migration_file) { root.join('db/migrations/20150613154832_create_deliveries.rb') }

    before do
      db_create
      db_apply
      db_drop

      File.open(migration_file, 'w') do |f|
        f.write <<-MIGRATION
Hanami::Model.migration do
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

    after { FileUtils.rm_rf(migration_file) }

    let(:architecture) { 'container' }

    describe 'default environment' do
      it 'creates and migrates database' do
        database   = root.join("db/#{ app_name }_development.sqlite3")
        connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
        version    = connection[:schema_migrations].to_a.last

        version.fetch(:filename).must_equal '20150613154832_create_deliveries.rb'
      end
    end

    describe 'test environment' do
      let(:hanami_env) { 'test' }

      it 'creates and migrates database' do
        database   = root.join("db/#{ app_name }_test.sqlite3")
        connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")
        version    = connection[:schema_migrations].to_a.last

        version.fetch(:filename).must_equal '20150613154832_create_deliveries.rb'
      end
    end

    describe 'production environment' do
      let(:hanami_env) { 'production' }

      it "doesn't create database" do
        database   = root.join("db/#{ app_name }.sqlite3")
        connection = Sequel.connect("#{ adapter_prefix }sqlite://#{ database }")

        connection.tables.must_be :empty?
      end
    end
  end

  describe 'version' do
    before do
      write_migrations

      db_create
      db_migrate
    end

    architectures.keys.each do |arch|
      describe "with #{ arch } architecture" do
        let(:architecture) { arch }

        describe 'default environment' do
          it 'prints current database version' do
            out = db_version

            out.must_equal "20150613152815\n"
          end
        end

        describe 'test environment' do
          let(:hanami_env) { 'test' }

          it 'prints current database version' do
            out = db_version

            out.must_equal "20150613152815\n"
          end
        end

        describe 'production environment' do
          let(:hanami_env) { 'production' }

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

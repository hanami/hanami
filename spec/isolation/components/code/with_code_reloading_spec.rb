RSpec.describe "Components: code", type: :integration do
  describe "with code reloading" do
    it "reloads code under lib/" do
      with_project do
        generate_model "user"
        generate_migration "create_users", <<-EOF
Hanami::Model.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String
    end
  end
end
EOF
        hanami "db prepare"

        hanami "generate mailer welcome"
        require Pathname.new(Dir.pwd).join("config", "environment")
        expect(Hanami.code_reloading?).to be(true)

        Hanami::Components.resolve('code')

        expect(defined?(User)).to             eq('constant')
        expect(defined?(UserRepository)).to   eq('constant')
        expect(defined?(Mailers::Welcome)).to eq('constant')

        rewrite "lib/bookshelf/entities/user.rb", <<-EOF
class User < Hanami::Entity
  def upcase_name
    name.upcase
  end
end
EOF

        rewrite "lib/bookshelf/repositories/user_repository.rb", <<-EOF
class UserRepository < Hanami::Repository
  def create_with_name
    create(name: 'l')
  end
end
EOF

        rewrite "lib/bookshelf/mailers/welcome.rb", <<-EOF
class Mailers::Welcome
  include Hanami::Mailer

  from    '<from>'
  to      '<to>'
  subject 'Ciao'
end
EOF
        Hanami.boot # this resolves `code` again AND configures Hanami::Model so we can connect to the db

        user = UserRepository.new.create_with_name
        expect(user.upcase_name).to eq('L')

        expect(Mailers::Welcome.subject).to eq('Ciao')
      end
    end
  end
end

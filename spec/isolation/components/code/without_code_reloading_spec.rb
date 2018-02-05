RSpec.describe "Components: code", type: :integration do
  describe "without code reloading" do
    it "doesn't reload code under lib/" do
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
        expect(Hanami).to receive(:code_reloading?).at_least(:once).and_return(false)

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

        expect { UserRepository.new.create_with_name }.to raise_error(NoMethodError, %r{undefined method `create_with_name'})
        expect(Mailers::Welcome.subject).to eq('Hello')
      end
    end
  end
end

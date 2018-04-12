RSpec.describe "Sessions", type: :integration do
  it "shows welcome page" do
    with_project do
      server do
        visit "/"

        expect(page).to have_title("Hanami | The web, with simplicity")

        expect(page).to have_content("The web, with simplicity.")
        expect(page).to have_content("Hanami is Open Source Software for MVC web development with Ruby.")
        expect(page).to have_content("bundle exec hanami generate action web home#index --url=/")
      end
    end
  end

  it "is empty by default" do
    with_project do
      prepare

      server do
        visit '/'

        expect(current_path).to eq('/')
        expect(page).to         have_content('Sign in')
      end
    end
  end

  xit "preserves data across requests" do
    with_project do
      prepare

      server do
        visit '/'
        expect(current_path).to eq('/')

        click_link('Sign in')
        expect(current_path).to eq('/signin')

        within 'form#signin-form' do
          click_button 'Sign in'
        end

        visit '/' # Without this, Capybara losts the session.

        expect(current_path).to eq('/')
        expect(page).to have_content("Welcome, Luca")
      end
    end
  end

  xit "clears the session" do
    with_project do
      prepare

      server do
        given_signedin_user

        click_link "Sign out"

        expect(current_path).to eq('/')
        expect(page).to_not have_content("Welcome, Luca")
      end
    end
  end

  context "when sessions aren't enabled" do
    # TODO: verify if this behavior is still required for 2.0
    xit "raises error when trying to use `session'" do
      with_project do
        generate "action web home#index --url=/"

        rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index < Hanami::Action
    def call(_req, res)
      res.body = req.session[:foo]
    end
  end
end
EOF
        server do
          visit "/"
          expect(page).to have_content("To use `session', please enable sessions for the current app.")
        end
      end
    end

    # TODO: verify if this behavior is still required for 2.0
    xit "raises error when trying to use `flash'" do
      with_project do
        generate "action web home#index --url=/"

        rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index < Hanami::Action
    def call(_req, res)
      res.body = res.flash[:notice]
    end
  end
end
EOF
        server do
          visit "/"
          expect(page).to have_content("To use `flash', please enable sessions for the current app.")
        end
      end
    end
  end

  private

  def prepare
    # Enable sessions
    replace "apps/web/application.rb", "# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']", "sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']"

    generate_user
    generate_actions
  end

  def generate_user # rubocop:disable Metrics/MethodLength
    generate_model     "user"
    generate_migration "create_users", <<-EOF
Hanami::Model.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String
    end

    execute "INSERT INTO users (name) VALUES('Luca')"
  end
end
EOF

    hanami "db prepare"
  end

  def generate_actions
    generate_home
    generate_signin
    generate_signout
  end

  def generate_home # rubocop:disable Metrics/MethodLength
    generate "action web home#index --url=/"
    replace "apps/web/config/routes.rb", "home#index", 'root to: "home#index"'

    rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web
  module Controllers
    module Home
      class Index < Hanami::Action
        def call(req, res)
          res[:current_user] = UserRepository.new.find(req.session[:user_id])
        end
      end
    end
  end
end
EOF

    rewrite "apps/web/templates/home/index.html.erb", <<-EOF
<h1>Bookshelf</h1>

<% if current_user.nil? %>
  <%= link_to "Sign in", "/signin" %>
<% else %>
  Welcome, <%= current_user.name %>
  <%= link_to "Sign out", "/signout" %>
<% end %>
EOF
  end

  def generate_signin
    generate_signin_new_action
    generate_signin_create_action
  end

  def generate_signin_new_action
    generate "action web sessions#new --url=/signin --method=GET"
    rewrite "apps/web/templates/sessions/new.html.erb", <<-EOF
<h1>Sign in</h1>

<%=
  form_for :signin, "/signin", id: "signin-form" do
    div do
      button "Sign in"
    end
  end
%>
EOF
  end

  def generate_signin_create_action
    generate "action web sessions#create --url=/signin --method=POST"
    rewrite "apps/web/controllers/sessions/create.rb", <<-EOF
module Web
  module Controllers
    module Sessions
      class Create < Hanami::Action
        def call(*, res)
          res.session[:user_id] = UserRepository.new.first.id
          res.redirect_to routes.root_url
        end
      end
    end
  end
end
EOF
  end

  def generate_signout
    generate "action web sessions#destroy --url=/signout --method=GET"

    rewrite "apps/web/controllers/sessions/destroy.rb", <<-EOF
module Web
  module Controllers
    module Sessions
      class Destroy < Hanami::Action
        def call(*, res)
          res.session[:user_id] = nil
          res.redirect_to routes.root_url
        end
      end
    end
  end
end
EOF
  end

  def given_signedin_user # rubocop:disable Metrics/AbcSize
    visit '/'
    expect(current_path).to eq('/')

    click_link('Sign in')
    expect(current_path).to eq('/signin')

    within 'form#signin-form' do
      click_button 'Sign in'
    end

    visit '/' # Without this, Capybara losts the session.

    expect(current_path).to eq('/')
    expect(page).to have_content("Welcome, Luca")
  end
end

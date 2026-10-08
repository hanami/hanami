# frozen_string_literal: true

require "dry/inflector"
require "hanami/slice/router"
require "json"

RSpec.describe "Router / Resource routes" do
  let(:router) { Hanami::Slice::Router.new(routes:, resolver:, inflector: Dry::Inflector.new) {} }

  let(:resolver) { Hanami::Slice::Routing::Resolver.new(slice:) }
  let(:slice) {
    Class.new(Hanami::Slice).tap { |slice|
      allow(slice).to receive(:container) { actions_container }
      allow(slice).to receive(:slices) { {reviews: child_slice} }
    }
  }
  let(:child_slice) {
    Class.new(Hanami::Slice).tap { |slice|
      allow(slice).to receive(:container) { actions_container("[reviews]") }
    }
  }
  def actions_container(prefix = nil)
    Hash.new { |_hsh, key|
      Class.new { |klass|
        klass.define_method(:call) do |env|
          body = key
          body = "#{body} #{JSON.generate(env["router.params"])}" if env["router.params"].any?
          body = "#{prefix}#{body}" if prefix
          [200, {}, body]
        end
      }.new
    }.tap { |container|
      def container.resolve(key) = self[key]
    }
  end

  let(:app) { Rack::MockRequest.new(router) }
  def routed(method, url)
    app.request(method, url).body
  end

  describe "resources" do
    let(:routes) { proc { resources :posts } }

    it "routes all RESTful actions to the resource" do
      expect(routed("GET", "/posts")).to eq %(actions.posts.index)
      expect(routed("GET", "/posts/new")).to eq %(actions.posts.new)
      expect(routed("POST", "/posts")).to eq %(actions.posts.create)
      expect(routed("GET", "/posts/1")).to eq %(actions.posts.show {"id":"1"})
      expect(routed("GET", "/posts/1/edit")).to eq %(actions.posts.edit {"id":"1"})
      expect(routed("PATCH", "/posts/1")).to eq %(actions.posts.update {"id":"1"})
      expect(routed("DELETE", "/posts/1")).to eq %(actions.posts.destroy {"id":"1"})

      expect(router.path("posts")).to eq "/posts"
      expect(router.path("new_post")).to eq "/posts/new"
      expect(router.path("edit_post", id: 1)).to eq "/posts/1/edit"
    end

    describe "with :only" do
      let(:routes) { proc { resources :posts, only: %i[index show] } }

      it "routes only the given actions to the resource" do
        expect(routed("GET", "/posts")).to eq %(actions.posts.index)
        expect(routed("GET", "/posts/1")).to eq %(actions.posts.show {"id":"1"})

        expect(routed("GET", "/posts/new")).not_to eq %(actions.posts.new)
        expect(routed("POST", "/posts")).to eq "Method Not Allowed"
        expect(routed("GET", "/posts/1/edit")).to eq "Not Found"
        expect(routed("PATCH", "/posts/1")).to eq "Method Not Allowed"
        expect(routed("DELETE", "/posts/1")).to eq "Method Not Allowed"
      end
    end

    describe "with :except" do
      let(:routes) { proc { resources :posts, except: %i[edit update destroy] } }

      it "routes all except the given actions to the resource" do
        expect(routed("GET", "/posts")).to eq %(actions.posts.index)
        expect(routed("GET", "/posts/new")).to eq %(actions.posts.new)
        expect(routed("POST", "/posts")).to eq %(actions.posts.create)
        expect(routed("GET", "/posts/1")).to eq %(actions.posts.show {"id":"1"})

        expect(routed("GET", "/posts/1/edit")).to eq "Not Found"
        expect(routed("PATCH", "/posts/1")).to eq "Method Not Allowed"
        expect(routed("DELETE", "/posts/1")).to eq "Method Not Allowed"
      end
    end

    describe "with :to" do
      let(:routes) { proc { resources :posts, to: "articles" } }

      it "uses actions from the given container key namespace" do
        expect(routed("GET", "/posts")).to eq %(actions.articles.index)
        expect(routed("GET", "/posts/new")).to eq %(actions.articles.new)
        expect(routed("POST", "/posts")).to eq %(actions.articles.create)
        expect(routed("GET", "/posts/1")).to eq %(actions.articles.show {"id":"1"})
        expect(routed("GET", "/posts/1/edit")).to eq %(actions.articles.edit {"id":"1"})
        expect(routed("PATCH", "/posts/1")).to eq %(actions.articles.update {"id":"1"})
        expect(routed("DELETE", "/posts/1")).to eq %(actions.articles.destroy {"id":"1"})
      end
    end

    describe "witih :path" do
      let(:routes) { proc { resources :posts, path: "articles" } }

      it "uses the given path for the routes" do
        expect(routed("GET", "/articles")).to eq %(actions.posts.index)
        expect(routed("GET", "/articles/new")).to eq %(actions.posts.new)
        expect(routed("POST", "/articles")).to eq %(actions.posts.create)
        expect(routed("GET", "/articles/1")).to eq %(actions.posts.show {"id":"1"})
        expect(routed("GET", "/articles/1/edit")).to eq %(actions.posts.edit {"id":"1"})
        expect(routed("PATCH", "/articles/1")).to eq %(actions.posts.update {"id":"1"})
        expect(routed("DELETE", "/articles/1")).to eq %(actions.posts.destroy {"id":"1"})
      end
    end

    describe "with :as" do
      let(:routes) { proc { resources :posts, as: :articles } }

      it "uses the given name for the route names" do
        expect(routed("GET", "/posts")).to eq %(actions.posts.index)
        expect(routed("GET", "/posts/1")).to eq %(actions.posts.show {"id":"1"})

        expect(router.path("articles")).to eq "/posts"
        expect(router.path("article", id: 1)).to eq "/posts/1"
        expect(router.path("new_article")).to eq "/posts/new"
        expect(router.path("edit_article", id: 1)).to eq "/posts/1/edit"
      end
    end

    describe "with an uncountable name" do
      let(:routes) { proc { resources :news } }

      it "adds an _index suffix to the collection route names" do
        expect(routed("GET", "/news")).to eq %(actions.news.index)
        expect(routed("POST", "/news")).to eq %(actions.news.create)
        expect(routed("GET", "/news/1")).to eq %(actions.news.show {"id":"1"})

        expect(router.path("news_index")).to eq "/news"
        expect(router.path("news", id: 1)).to eq "/news/1"
        expect(router.path("new_news")).to eq "/news/new"
        expect(router.path("edit_news", id: 1)).to eq "/news/1/edit"
      end
    end

    describe "with an uncountable :as" do
      let(:routes) { proc { resources :posts, as: :series } }

      it "adds an _index suffix to the collection route names" do
        expect(router.path("series_index")).to eq "/posts"
        expect(router.path("series", id: 1)).to eq "/posts/1"
      end
    end
  end

  describe "resource" do
    let(:routes) { proc { resource :profile } }

    it "routes all RESTful actions (except index) to the resource" do
      expect(routed("GET", "/profile/new")).to eq %(actions.profile.new)
      expect(routed("POST", "/profile")).to eq %(actions.profile.create)
      expect(routed("GET", "/profile")).to eq %(actions.profile.show)
      expect(routed("GET", "/profile/edit")).to eq %(actions.profile.edit)
      expect(routed("PATCH", "/profile")).to eq %(actions.profile.update)
      expect(routed("DELETE", "/profile")).to eq %(actions.profile.destroy)

      expect(routed("GET", "/profiles")).to eq "Not Found"
      expect(routed("GET", "/profiles/1")).to eq "Not Found"
      expect(routed("GET", "/profile/1")).to eq "Not Found"

      expect(router.path("profile")).to eq "/profile"
      expect(router.path("new_profile")).to eq "/profile/new"
      expect(router.path("edit_profile")).to eq "/profile/edit"
    end

    describe "with :only" do
      let(:routes) { proc { resource :profile, only: %i[show edit update] } }

      it "routes only the given actions to the resource" do
        expect(routed("GET", "/profile")).to eq %(actions.profile.show)
        expect(routed("GET", "/profile/edit")).to eq %(actions.profile.edit)
        expect(routed("PATCH", "/profile")).to eq %(actions.profile.update)

        expect(routed("GET", "/profile/new")).to eq "Not Found"
        expect(routed("POST", "/profile")).to eq "Method Not Allowed"
        expect(routed("DELETE", "/profile")).to eq "Method Not Allowed"
      end
    end

    describe "with :except" do
      let(:routes) { proc { resource :profile, except: %i[edit update destroy] } }

      it "routes all except the given actions to the resource" do
        expect(routed("GET", "/profile/new")).to eq %(actions.profile.new)
        expect(routed("POST", "/profile")).to eq %(actions.profile.create)
        expect(routed("GET", "/profile")).to eq %(actions.profile.show)

        expect(routed("GET", "/profile/edit")).to eq "Not Found"
        expect(routed("PATCH", "/profile")).to eq "Method Not Allowed"
        expect(routed("DELETE", "/profile")).to eq "Method Not Allowed"
      end
    end

    describe "with :to" do
      let(:routes) { proc { resource :profile, to: "user" } }

      it "uses actions from the given container key namespace" do
        expect(routed("GET", "/profile/new")).to eq %(actions.user.new)
        expect(routed("POST", "/profile")).to eq %(actions.user.create)
        expect(routed("GET", "/profile")).to eq %(actions.user.show)
        expect(routed("GET", "/profile/edit")).to eq %(actions.user.edit)
        expect(routed("PATCH", "/profile")).to eq %(actions.user.update)
        expect(routed("DELETE", "/profile")).to eq %(actions.user.destroy)
      end
    end

    describe "with :path" do
      let(:routes) { proc { resource :profile, path: "user" } }

      it "uses the given path for the routes" do
        expect(routed("GET", "/user/new")).to eq %(actions.profile.new)
        expect(routed("POST", "/user")).to eq %(actions.profile.create)
        expect(routed("GET", "/user")).to eq %(actions.profile.show)
        expect(routed("GET", "/user/edit")).to eq %(actions.profile.edit)
        expect(routed("PATCH", "/user")).to eq %(actions.profile.update)
        expect(routed("DELETE", "/user")).to eq %(actions.profile.destroy)
      end
    end

    describe "with :as" do
      let(:routes) { proc { resource :profile, as: :account } }

      it "uses the given name for the route names" do
        expect(routed("GET", "/profile")).to eq %(actions.profile.show)

        expect(router.path("account")).to eq "/profile"
        expect(router.path("new_account")).to eq "/profile/new"
        expect(router.path("edit_account")).to eq "/profile/edit"
      end
    end
  end

  describe "nested resources" do
    let(:routes) {
      proc {
        resources :cafes, only: :show do
          resources :reviews, only: :index do
            resources :comments, only: [:index, :new, :create]
          end
        end

        resource :profile, only: :show do
          resource :avatar, only: :show do
            resources :comments, only: :index
          end
        end
      }
    }

    it "routes to the nested resources" do
      expect(routed("GET", "/cafes/1")).to eq %(actions.cafes.show {"id":"1"})
      expect(routed("GET", "/cafes/1/reviews")).to eq %(actions.cafes.reviews.index {"cafe_id":"1"})
      expect(routed("GET", "/cafes/1/reviews/2/comments")).to eq %(actions.cafes.reviews.comments.index {"cafe_id":"1","review_id":"2"})

      expect(router.path("cafe", id: 1)).to eq "/cafes/1"
      expect(router.path("cafe_reviews", cafe_id: 1)).to eq "/cafes/1/reviews"
      expect(router.path("cafe_review_comments", cafe_id: 1, review_id: 1)).to eq "/cafes/1/reviews/1/comments"
      expect(router.path("new_cafe_review_comment", cafe_id: 1, review_id: 1)).to eq "/cafes/1/reviews/1/comments/new"

      expect(routed("GET", "/profile")).to eq %(actions.profile.show)
      expect(routed("GET", "/profile/avatar")).to eq %(actions.profile.avatar.show)
      expect(routed("GET", "/profile/avatar/comments")).to eq %(actions.profile.avatar.comments.index)
    end

    describe "with :as" do
      let(:routes) {
        proc {
          resources :cafes, only: :show, as: :coffee_shops do
            resources :reviews, only: :index, as: :ratings do
              get "/top", to: "cafes.reviews.top", as: :top
            end
          end

          resource :profile, only: :show, as: :account do
            resources :comments, only: :index
          end
        }
      }

      it "uses the given names for the nested route names" do
        expect(routed("GET", "/cafes/1/reviews")).to eq %(actions.cafes.reviews.index {"cafe_id":"1"})

        expect(router.path("coffee_shop", id: 1)).to eq "/cafes/1"
        expect(router.path("coffee_shop_ratings", cafe_id: 1)).to eq "/cafes/1/reviews"
        expect(router.path("coffee_shop_rating_top", cafe_id: 1, review_id: 2)).to eq "/cafes/1/reviews/2/top"

        expect(router.path("account_comments")).to eq "/profile/comments"
      end
    end

    describe "with :path" do
      let(:routes) {
        proc {
          resources :cafes, only: :show, path: "coffee-shops" do
            resources :reviews, only: :index
          end

          resources :posts, only: :show, path: "blog/posts" do
            resources :comments, only: :index
          end

          resources :comments, only: :show, path: "reviews" do
            resources :likes, only: :index
          end
        }
      }

      it "uses the resource name for the nested route params" do
        expect(routed("GET", "/coffee-shops/1/reviews")).to eq %(actions.cafes.reviews.index {"cafe_id":"1"})
        expect(routed("GET", "/blog/posts/1/comments")).to eq %(actions.posts.comments.index {"post_id":"1"})
        expect(routed("GET", "/reviews/1/likes")).to eq %(actions.comments.likes.index {"comment_id":"1"})

        expect(router.path("cafe_reviews", cafe_id: 1)).to eq "/coffee-shops/1/reviews"
      end
    end

    describe "under a singular resource with a plural name" do
      let(:routes) {
        proc {
          resource :settings, only: :show do
            resources :items, only: :index
          end
        }
      }

      it "uses the resource name as given for the nested route names" do
        expect(routed("GET", "/settings/items")).to eq %(actions.settings.items.index)

        expect(router.path("settings")).to eq "/settings"
        expect(router.path("settings_items")).to eq "/settings/items"
      end
    end
  end

  describe "standalone routes nested under resources" do
    let(:routes) {
      proc {
        resources :cafes, only: :show do
          get "/top-reviews", to: "cafes.top_reviews.index", as: :top_reviews
        end
      }
    }

    it "nests the standalone route under the resource" do
      expect(routed("GET", "/cafes/1")).to eq %(actions.cafes.show {"id":"1"})
      expect(routed("GET", "/cafes/1/top-reviews")).to eq %(actions.cafes.top_reviews.index {"cafe_id":"1"})

      expect(router.path("cafe_top_reviews", cafe_id: 1)).to eq "/cafes/1/top-reviews"
    end
  end

  describe "resources nested under scopes" do
    let(:routes) {
      proc {
        scope "coffee-lovers" do
          resources :cafes, only: :show do
            get "/top-reviews", to: "cafes.top_reviews.index", as: :top_reviews
          end
        end
      }
    }

    it "routes to the resources under the scope" do
      expect(routed("GET", "/coffee-lovers/cafes/1")).to eq %(actions.cafes.show {"id":"1"})
      expect(routed("GET", "/coffee-lovers/cafes/1/top-reviews")).to eq %(actions.cafes.top_reviews.index {"cafe_id":"1"})

      expect(router.path("coffee_lovers_cafe", id: 1)).to eq "/coffee-lovers/cafes/1"
      expect(router.path("coffee_lovers_cafe_top_reviews", cafe_id: 1)).to eq "/coffee-lovers/cafes/1/top-reviews"
    end
  end

  describe "slices nested under resources" do
    let(:routes) {
      proc {
        resources :cafes, only: :show do
          slice :reviews, at: "" do
            resources :reviews, only: :index
          end
        end
      }
    }

    it "routes to actions within the nested slice" do
      expect(routed("GET", "/cafes/1")).to eq %(actions.cafes.show {"id":"1"})
      expect(routed("GET", "/cafes/1/reviews")).to eq %([reviews]actions.cafes.reviews.index {"cafe_id":"1"})

      expect(router.path("cafe_reviews", cafe_id: 1)).to eq "/cafes/1/reviews"
    end
  end
end

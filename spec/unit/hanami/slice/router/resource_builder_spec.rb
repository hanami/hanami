# frozen_string_literal: true

require "dry/inflector"

RSpec.describe Hanami::Slice::Router::ResourceBuilder do
  let(:router) { double("router") }
  let(:inflector) { Dry::Inflector.new }
  let(:name) { :users }
  let(:type) { :plural }
  let(:options) { {} }

  subject(:builder) do
    described_class.new(
      router: router,
      inflector: inflector,
      name: name,
      type: type,
      options: options
    )
  end

  describe "#initialize" do
    it "sets basic attributes" do
      expect(builder.router).to eq router
      expect(builder.name).to eq :users
      expect(builder.type).to eq :plural
      expect(builder.options).to eq({})
    end

    it "sets default action_path from name" do
      expect(builder.action_path).to eq "users"
    end

    it "sets default path from name" do
      expect(builder.path).to eq "users"
    end

    it "sets default route_name for plural resources" do
      expect(builder.route_name).to eq "user"
    end

    context "with singular resource" do
      let(:type) { :singular }
      let(:name) { :profile }

      it "sets route_name to name for singular resources" do
        expect(builder.route_name).to eq "profile"
      end
    end

    context "with custom options" do
      let(:options) do
        {
          to: "admin/users",
          path: "members",
          as: "member"
        }
      end

      it "uses custom action_path" do
        expect(builder.action_path).to eq "admin.users"
      end

      it "uses custom path" do
        expect(builder.path).to eq "members"
      end

      it "uses custom route_name" do
        expect(builder.route_name).to eq "member"
      end
    end
  end

  describe "#normalize_action_path" do
    it "converts slash to dot notation" do
      expect(builder.normalize_action_path("admin/users")).to eq "admin.users"
    end

    it "handles string input" do
      expect(builder.normalize_action_path("users")).to eq "users"
    end

    it "handles symbol input" do
      expect(builder.normalize_action_path(:users)).to eq "users"
    end
  end

  describe "#build_routes" do
    let(:options) { { only: [:index, :show] } }

    before do
      allow(router).to receive(:get)
    end

    it "builds routes for allowed actions only" do
      expect(router).to receive(:get).with("/users", to: "users.index", as: "users")
      expect(router).to receive(:get).with("/users/:id", to: "users.show", as: "user")

      builder.build_routes
    end
  end

  describe "private methods" do
    describe "#allowed_actions" do
      context "with plural resource" do
        it "returns all plural actions by default" do
          expect(builder.send(:allowed_actions)).to eq %i[index new create show edit update destroy]
        end

        context "with :only option" do
          let(:options) { { only: [:index, :show] } }

          it "returns only specified actions" do
            expect(builder.send(:allowed_actions)).to eq [:index, :show]
          end
        end

        context "with :except option" do
          let(:options) { { except: [:destroy] } }

          it "returns all actions except specified ones" do
            expect(builder.send(:allowed_actions)).to eq %i[index new create show edit update]
          end
        end
      end

      context "with singular resource" do
        let(:type) { :singular }

        it "returns singular actions (no index)" do
          expect(builder.send(:allowed_actions)).to eq %i[new create show edit update destroy]
        end
      end
    end

    describe "#build_route_path" do
      it "builds correct path with suffix" do
        expect(builder.send(:build_route_path, "/new")).to eq "/users/new"
      end

      it "builds correct path without suffix" do
        expect(builder.send(:build_route_path, "")).to eq "/users"
      end

      context "with singular resource" do
        let(:type) { :singular }
        let(:name) { :profile }

        it "removes :id from paths for singular resources" do
          expect(builder.send(:build_route_path, "/:id/edit")).to eq "/profile/edit"
        end
      end
    end

    describe "#build_route_name" do
      it "builds correct route name for index action" do
        expect(builder.send(:build_route_name, :index, "")).to eq "users"
      end

      it "builds correct route name for other actions" do
        expect(builder.send(:build_route_name, :show, "")).to eq "user"
      end

      it "builds correct route name with prefix" do
        expect(builder.send(:build_route_name, :show, "edit_")).to eq "edit_user"
      end
    end

    describe "#resolve_suffix" do
      it "returns empty string for nil suffix" do
        expect(builder.send(:resolve_suffix, nil)).to eq ""
      end

      it "returns empty string for empty suffix" do
        expect(builder.send(:resolve_suffix, "")).to eq ""
      end

      it "returns suffix as-is for plural resources" do
        expect(builder.send(:resolve_suffix, "/:id/edit")).to eq "/:id/edit"
      end

      context "with singular resource" do
        let(:type) { :singular }

        it "removes :id from suffix for singular resources" do
          expect(builder.send(:resolve_suffix, "/:id/edit")).to eq "/edit"
        end
      end
    end
  end
end

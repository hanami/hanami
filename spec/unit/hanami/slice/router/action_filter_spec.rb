# frozen_string_literal: true

RSpec.describe Hanami::Slice::Router::ActionFilter do
  describe ".filter" do
    let(:default_actions) { %i[index new create show edit update destroy] }

    context "with no options" do
      it "returns all default actions" do
        result = described_class.filter(default_actions, {})
        expect(result).to eq default_actions
      end
    end

    context "with :only option" do
      it "returns only specified actions" do
        options = { only: [:index, :show] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq [:index, :show]
      end

      it "handles single action" do
        options = { only: :index }
        result = described_class.filter(default_actions, options)
        expect(result).to eq [:index]
      end

      it "filters out actions not in default list" do
        options = { only: [:index, :invalid_action] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq [:index]
      end

      it "returns empty array if no valid actions specified" do
        options = { only: [:invalid_action] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq []
      end
    end

    context "with :except option" do
      it "returns all actions except specified ones" do
        options = { except: [:destroy] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq %i[index new create show edit update]
      end

      it "handles multiple excluded actions" do
        options = { except: [:new, :create, :destroy] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq %i[index show edit update]
      end

      it "handles single excluded action" do
        options = { except: :destroy }
        result = described_class.filter(default_actions, options)
        expect(result).to eq %i[index new create show edit update]
      end

      it "ignores invalid actions in except list" do
        options = { except: [:destroy, :invalid_action] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq %i[index new create show edit update]
      end

      it "returns all actions if except contains no valid actions" do
        options = { except: [:invalid_action] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq default_actions
      end
    end

    context "with both :only and :except options" do
      it "prioritizes :only option and ignores :except" do
        options = { only: [:index, :show], except: [:destroy] }
        result = described_class.filter(default_actions, options)
        expect(result).to eq [:index, :show]
      end
    end
  end
end

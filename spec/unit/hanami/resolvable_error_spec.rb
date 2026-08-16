# frozen_string_literal: true

RSpec.describe Hanami::ResolvableError do
  let(:context) { Struct.new(:app, :slice, :request).new(:the_app, nil, nil) }

  describe "guidance" do
    subject(:error) do
      Class.new(StandardError) do
        include Hanami::ResolvableError

        def key = "STRIPE_API_KEY"

        resolution "Add it to .env.local" do
          snippet "STRIPE_API_KEY="
          note "Restart afterwards."
        end
      end.new("boom")
    end

    it "builds a resolution with the declared content" do
      resolution = error.resolutions.first

      expect(resolution.name).to eq("Add it to .env.local")
      expect(resolution.snippet).to eq("STRIPE_API_KEY=")
      expect(resolution.note).to eq("Restart afterwards.")
    end

    # This is the entire signal the error page uses to decide whether to offer a button, so a
    # guidance resolution reporting itself as callable would put a button on nothing.
    it "does not respond to #call" do
      expect(error.resolutions.first).not_to respond_to(:call)
    end

    it "defaults items to an empty array" do
      expect(error.resolutions.first.items).to eq([])
    end
  end

  describe "runnable" do
    subject(:error) do
      Class.new(StandardError) do
        include Hanami::ResolvableError

        def pending = ["20250811103012_create_books.rb"]

        resolution "Run pending migrations" do
          command "bundle exec hanami db migrate"
          items pending
          run { |context| "migrated for #{context.app}" }
        end
      end.new("boom")
    end

    it "responds to #call once a run block is declared" do
      expect(error.resolutions.first).to respond_to(:call)
    end

    it "runs the block against the error, with the context" do
      expect(error.resolutions.first.call(context)).to eq("migrated for the_app")
    end

    it "carries a command alongside the button, as one fix offered two ways" do
      resolution = error.resolutions.first

      expect(resolution.command).to eq("bundle exec hanami db migrate")
      expect(resolution).to respond_to(:call)
    end

    it "is not destructive by default" do
      expect(error.resolutions.first).not_to be_destructive
    end
  end

  describe "reading the error's own state" do
    it "forwards anything the builder does not define to the error" do
      error = Class.new(StandardError) do
        include Hanami::ResolvableError

        attr_reader :names

        def initialize(names)
          @names = names
          super("boom")
        end

        resolution "Add them" do
          items names
          snippet names.map { "#{_1}=" }.join("\n")
        end
      end.new(%w[A B])

      resolution = error.resolutions.first

      expect(resolution.items).to eq(%w[A B])
      expect(resolution.snippet).to eq("A=\nB=")
    end

    # NameError rather than NoMethodError: a bare identifier could be a local variable, so Ruby
    # raises the parent class. Both carry did_you_mean suggestions, which is the part that
    # matters when someone typos in a declaration.
    it "raises for something neither the builder nor the error defines" do
      error = Class.new(StandardError) do
        include Hanami::ResolvableError

        resolution("Broken") { nonsense }
      end.new("boom")

      expect { error.resolutions }.to raise_error(NameError, /nonsense/)
    end

    # Declarations sit in the class body, where no instance exists, so they cannot be evaluated
    # until an error is actually raised.
    it "evaluates the block per instance, not once at declaration" do
      klass = Class.new(StandardError) do
        include Hanami::ResolvableError

        attr_reader :value

        def initialize(value)
          @value = value
          super("boom")
        end

        resolution("Show it") { note value }
      end

      expect(klass.new("first").resolutions.first.note).to eq("first")
      expect(klass.new("second").resolutions.first.note).to eq("second")
    end
  end

  describe "destructive resolutions" do
    subject(:error) do
      Class.new(StandardError) do
        include Hanami::ResolvableError

        resolution "Roll back", destructive: true do
          run { "rolled back" }
        end
      end.new("boom")
    end

    it "carries the flag through" do
      expect(error.resolutions.first).to be_destructive
    end
  end

  describe "several resolutions" do
    subject(:error) do
      Class.new(StandardError) do
        include Hanami::ResolvableError

        resolution("First") { note "one" }
        resolution("Second") { run { "two" } }
        resolution("Third") { note "three" }
      end.new("boom")
    end

    it "keeps declaration order" do
      expect(error.resolutions.map(&:name)).to eq(%w[First Second Third])
    end

    it "mixes guidance and runnable freely" do
      expect(error.resolutions.map { _1.respond_to?(:call) }).to eq([false, true, false])
    end
  end

  describe "inheritance" do
    let(:parent) do
      Class.new(StandardError) do
        include Hanami::ResolvableError

        resolution("Inherited") { note "from the parent" }
      end
    end

    let(:child) do
      Class.new(parent) do
        resolution("Added") { note "from the child" }
      end
    end

    it "inherits the parent's resolutions and appends its own" do
      expect(child.new("boom").resolutions.map(&:name)).to eq(%w[Inherited Added])
    end

    it "does not alter the parent when the child declares one" do
      child # force the subclass to be defined

      expect(parent.new("boom").resolutions.map(&:name)).to eq(%w[Inherited])
    end
  end

  describe "an error with no resolutions" do
    it "returns an empty array rather than nil" do
      error = Class.new(StandardError) { include Hanami::ResolvableError }.new("boom")

      expect(error.resolutions).to eq([])
    end
  end

  describe "the underlying convention" do
    # The error page never sees this module. It reads `#resolutions` and duck-types what comes
    # back, which is what lets gems that cannot depend on hanami offer resolutions too.
    it "produces objects answering the duck-typed contract" do
      error = Class.new(StandardError) do
        include Hanami::ResolvableError

        resolution("Fix it") { run { "done" } }
      end.new("boom")

      resolution = error.resolutions.first

      expect(error).to respond_to(:resolutions)
      expect(resolution).to respond_to(:name)
      expect(resolution).to respond_to(:call)
      expect(resolution).to respond_to(:destructive?)
    end
  end
end

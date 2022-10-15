# frozen_string_literal: true

RSpec.describe "Container / prepare_container", :app_integration do
  # (Most of) the examples below make their expectations on a `container_to_prepare`,
  # which is the container yielded to the `Slice.prepare_container` block _at the moment
  # it is called_.
  #
  # This around hook ensures the examples are run at the right time and container is
  # available to each.
  around(in_prepare_container: true) do |example|
    # Eagerly capture @loaded_features here (see spec/support/app_integration.rb) since
    # around hooks are run before any before hooks (where we ordinarily capture
    # @loaded_features), and by invoking `example_group_instance.subject` below, we're
    # making requires that we want to ensure are properly cleaned between examples.
    @loaded_features = $LOADED_FEATURES.dup

    slice = example.example_group_instance.subject

    slice.prepare_container do |container|
      example.example.example_group.let(:container_to_prepare) { container }
      example.run
    end

    # The prepare_container block is called when the slice is prepared
    slice.prepare

    autoloaders_teardown!
  end

  describe "in app", :in_prepare_container do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/.keep", ""
      end
    end

    subject {
      with_directory(@dir) { require "hanami/setup" }
      Hanami.app
    }

    it "receives the container for the app" do
      expect(container_to_prepare).to be TestApp::Container
    end

    specify "the container has been already configured by the app" do
      expect(container_to_prepare.config.component_dirs.dir("app")).to be
    end

    specify "the container is not yet marked as configured" do
      expect(container_to_prepare).not_to be_configured
    end

    describe "after app is prepared", in_prepare_container: false do
      before do
        subject.prepare_container do |container|
          container.config.name = :custom_name
        end
      end

      it "preserves any container configuration changes made via the block" do
        expect { subject.prepare }
          .to change { subject.container.config.name }
          .to :custom_name

        expect(subject.container).to be_configured
      end
    end
  end

  describe "in slice", :in_prepare_container do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/.keep", ""
      end
    end

    subject {
      with_directory(@dir) { require "hanami/setup" }
      Hanami.app.register_slice(:main)
    }

    it "receives the container for the slice" do
      expect(container_to_prepare).to be Main::Container
    end

    specify "the container has been already configured by the slice" do
      expect(container_to_prepare.config.component_dirs.dir("")).to be
    end

    specify "the container is not yet marked as configured" do
      expect(container_to_prepare).not_to be_configured
    end

    describe "after slice is prepared", in_prepare_container: false do
      before do
        subject.prepare_container do |container|
          container.config.name = :custom_name
        end
      end

      it "preserves any container configuration changes made via the block" do
        expect { subject.prepare }
          .to change { subject.container.config.name }
          .to :custom_name

        expect(subject.container).to be_configured
      end
    end
  end
end

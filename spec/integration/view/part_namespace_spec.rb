# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Part namespace", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
        config.root = "/test_app"
      end
    end

    Hanami.app.instance_eval(&app_hook) if respond_to?(:app_hook)
    Hanami.app.register_slice :main
    Hanami.app.prepare

    module TestApp
      module Views
        module Parts
        end
      end
    end

    module TestApp
      class View < Hanami::View
      end
    end

    module TestApp
      module Views
        module Article
          class Index < TestApp::View
          end
        end
      end
    end
  end

  subject(:part_namespace) { view_class.config.part_namespace }
  let(:view_class) { TestApp::Views::Article::Index }

  it "is View::Parts" do
    is_expected.to eq TestApp::Views::Parts
  end
end

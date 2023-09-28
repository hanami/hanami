# frozen_string_literal: true

require "rake"
require "hanami/cli/bundler"

RSpec.describe "Rake tasks", :app_integration do
  describe "assets:precompile" do
    before do
      allow(Hanami).to receive(:bundled?)
      allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(hanami_assets_bundled)
    end

    context "when hanami-assets is bundled" do
      let(:hanami_assets_bundled) { true }

      xit "compiles assets" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "Rakefile", <<~RUBY
            # frozen_string_literal: true

            require "hanami/rake_tasks"
          RUBY

          write "app/assets/js/app.js", <<~JS
            console.log("Hello from index.js");
          JS

          before_prepare if respond_to?(:before_prepare)
          require "hanami/prepare"

          expect_any_instance_of(Hanami::CLI::Bundler).to receive(:hanami_exec).with("assets compile").and_return(true)

          Rake::Task["assets:precompile"].invoke
        end
      end

      it "doesn't list the task" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "Rakefile", <<~RUBY
            # frozen_string_literal: true

            require "hanami/rake_tasks"
          RUBY

          before_prepare if respond_to?(:before_prepare)
          require "hanami/prepare"

          output = `bundle exec rake -T`
          expect(output).to_not include("assets:precompile")
        end
      end
    end

    context "when hanami-assets is not bundled" do
      let(:hanami_assets_bundled) { false }

      it "raises error" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "Rakefile", <<~RUBY
            # frozen_string_literal: true

            require "hanami/rake_tasks"
          RUBY

          write "app/assets/js/app.js", <<~JS
            console.log("Hello from index.js");
          JS

          before_prepare if respond_to?(:before_prepare)
          require "hanami/prepare"

          expect { Rake::Task["assets:precompile"].invoke }.to raise_error do |exception|
            expect(exception).to be_a(RuntimeError)
            expect(exception.message).to match(/Don't know how to build task 'assets:precompile'/)
          end
        end
      end
    end
  end
end

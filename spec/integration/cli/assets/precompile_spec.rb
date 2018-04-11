require 'json'

RSpec.describe 'hanami assets', type: :integration do
  describe 'precompile' do
    it "precompiles assets" do
      gems = ['sass', 'coffee-script']

      Platform.match do
        os(:linux).engine(:ruby)  { gems.push('therubyracer') }
        os(:linux).engine(:jruby) { gems.push('therubyrhino') }
      end

      with_project("bookshelf_assets_precompile", gems: gems) do
        #
        # Web assets
        #
        write "apps/web/assets/javascripts/application.js.coffee", <<-EOF
class Application
  constructor: () ->
    @init = true
EOF
        write "apps/web/assets/stylesheets/_colors.scss", <<-EOF
$background-color: #f5f5f5;
EOF

        write "apps/web/assets/stylesheets/application.css.scss", <<-EOF
@import 'colors';

body {
  background-color: $background-color;
}
EOF
        #
        # Admin assets
        #
        generate "app admin"
        write "apps/admin/assets/javascripts/dashboard.js.coffee", <<-EOF
class Dashboard
  constructor: (@data) ->
EOF

        #
        # Precompile
        #
        RSpec::Support::Env['HANAMI_ENV'] = 'production'
        hanami "assets precompile"

        # rubocop:disable Lint/ImplicitStringConcatenation
        # rubocop:disable Style/FirstParameterIndentation

        #
        # Verify manifest
        #
        manifest = retry_exec(Errno::ENOENT) do
          File.read("public/assets.json")
        end

        expect(JSON.parse(manifest)).to be_kind_of(Hash) # assert it's a well-formed JSON

        expect(manifest).to include(%("/assets/admin/dashboard.js":{"target":"/assets/admin/dashboard-39744f9626a70683b6c2d46305798883.js","sri":["sha256-1myPVWoqrq+uAVP2DSkmAown+5dm0x61+E3AjlGOKEc="]}))
        expect(manifest).to include(%("/assets/admin/favicon.ico":{"target":"/assets/admin/favicon-b0979f93c7f7246ac70949a80f7cbdfd.ico","sri":["sha256-PLEDhpDsTBpxl1KtXjzBjg+PUG67zpf05B1z2db4iJU="]}))
        expect(manifest).to include(%("/assets/application.css":{"target":"/assets/application-adb4104884aadde9abfef0bd98ac461e.css","sri":["sha256-S6V565W2In9pWE0uzMASpp58xCg32TN3at3Fv4g9aRA="]}))
        expect(manifest).to include(%("/assets/application.js":{"target":"/assets/application-bb8f10498d83d401db238549409dc4c5.js","sri":["sha256-9m4OTbWigbDPp4oCe1LZz9isqidvW1c3jNL6mXMj2xs="]}))
        expect(manifest).to include(%("/assets/favicon.ico":{"target":"/assets/favicon-b0979f93c7f7246ac70949a80f7cbdfd.ico","sri":["sha256-PLEDhpDsTBpxl1KtXjzBjg+PUG67zpf05B1z2db4iJU="]}))

        #
        # Verify web assets (w/ checksum)
        #
        expect("public/assets/application-adb4104884aadde9abfef0bd98ac461e.css").to have_file_content <<-EOF
body {background-color: #f5f5f5}
EOF

        expect("public/assets/application-bb8f10498d83d401db238549409dc4c5.js").to have_file_content \
"""
(function(){var Application;Application=(function(){function Application(){this.init=true;}
return Application;})();}).call(this);
"""

        expect("public/assets/favicon-b0979f93c7f7246ac70949a80f7cbdfd.ico").to be_an_existing_file

        #
        # Verify web assets (w/o checksum)
        #
        expect("public/assets/application.css").to have_file_content <<-EOF
body {background-color: #f5f5f5}
EOF

        expect("public/assets/application.js").to have_file_content \
"""
(function(){var Application;Application=(function(){function Application(){this.init=true;}
return Application;})();}).call(this);
"""

        expect("public/assets/favicon.ico").to be_an_existing_file

        #
        # Verify admin assets (w/ checksum)
        #
        expect("public/assets/admin/dashboard-39744f9626a70683b6c2d46305798883.js").to have_file_content \
"""
(function(){var Dashboard;Dashboard=(function(){function Dashboard(data){this.data=data;}
return Dashboard;})();}).call(this);
"""

        expect("public/assets/admin/favicon-b0979f93c7f7246ac70949a80f7cbdfd.ico").to be_an_existing_file

        #
        # Verify admin assets (w/o checksum)
        #
        expect("public/assets/admin/dashboard.js").to have_file_content \
"""
(function(){var Dashboard;Dashboard=(function(){function Dashboard(data){this.data=data;}
return Dashboard;})();}).call(this);
"""

        expect("public/assets/admin/favicon.ico").to be_an_existing_file

        # rubocop:enable Lint/ImplicitStringConcatenation
        # rubocop:enable Style/FirstParameterIndentation
      end
    end

    it "prints help message" do
      with_project do
        output = <<-OUT
Command:
  hanami assets precompile

Usage:
  hanami assets precompile

Description:
  Precompile assets for deployment

Options:
  --help, -h                      	# Print this help

Examples:
  hanami assets precompile                       # Basic usage
  hanami assets precompile HANAMI_ENV=production # Precompile assets for production environment
OUT

        run_command "hanami assets precompile --help", output
      end
    end
  end
end

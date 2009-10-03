# Fork of Dan Pickett's Enlightened template
# based on Suspenders by Thoughtbot
# influenced by Mike Gunderloy's rails template - http://gist.github.com/145676

# ====================
# Gems
# ====================

gem 'thoughtbot-hoptoad_notifier', :lib => "hoptoad_notifier"
gem 'thoughtbot-clearance', :lib => 'clearance', :source => 'http://gems.github.com'
gem 'josevalim-inherited_resources', :lib => 'inherited_resources', :source => 'http://gems.github.com'
gem 'justinfrench-formtastic', :lib => 'formtastic', :source => 'http://gems.github.com'
gem 'thoughtbot-paperclip', :lib => 'paperclip'
gem 'compass'

# Generate cucumber before adding test gems
generate :cucumber

# Cucumber gems
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :env => 'cucumber'
gem 'faker', :env => 'cucumber'

# Test gems
gem 'thoughtbot-shoulda', :lib => 'shoulda', :env => 'test'
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :env => 'test'
gem 'jnunemaker-matchy', :lib => 'matchy', :env => 'test'
gem 'rr', :env => 'test'
gem 'faker', :env => 'test'

rake 'gems:install', :sudo => true

# ====================
# Unnecessary files
# ====================

[ 'README',
  'doc/README_FOR_APP',
  'public/index.html',
  'public/favicon.ico',
  'public/images/rails.png',

  # Not using Prototype.js
  'public/javascripts/controls.js',
  'public/javascripts/dragdrop.js',
  'public/javascripts/effects.js',
  'public/javascripts/prototype.js',

  'test/performance/browsing_test.rb'

].each do |path|
  FileUtils.rm path
end

# Fixtures are evil
FileUtils.rm_rf("test/fixtures")


# ====================
# Controllers
# ====================

file 'app/controllers/application_controller.rb', <<-CODE
class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  include HoptoadNotifier::Catcher
end
CODE

file 'app/controllers/home_controller.rb', <<-CODE
class HomeController < ApplicationController
  def index
  end
end
CODE

# Clear all the cruft from routes.rb
file 'config/routes.rb', <<-CODE
ActionController::Routing::Routes.draw do |map|
end
CODE

route "map.root :controller => 'home'"

# Create a blank home view
file 'app/views/home/index.erb', ''


# ====================
# Layouts
# ====================

file 'app/helpers/application_helper.rb',
%q{module ApplicationHelper
  def body_class
    "#{ controller.controller_name } #{ controller.controller_name }-#{ controller.action_name }"
  end
end
}

file 'app/views/layouts/_flashes.html.erb', <<-CODE
<div id="flash">
  <% flash.each do |key, value| -%>
    <div id="flash_<%= key %>"><%=h value %></div>
  <% end -%>
</div>
CODE

file 'app/views/layouts/application.html.erb', <<-CODE
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title></title>
    
    <%= stylesheet_link_tag 'main' %>
  </head>
  <body class="<%= body_class %>">
    <%= render :partial => 'layouts/flashes' -%>
    <%= yield %>
  </body>
</html>
CODE


#====================
# Initializers
#====================

initializer 'hoptoad.rb', <<-CODE
HoptoadNotifier.configure do |config|
  config.api_key = 'HOPTOAD-KEY'
end
CODE

initializer 'time_formats.rb', <<-CODE
# Example time formats
{ :short_date => "%x", :long_date => "%a, %b %d, %Y" }.each do |k, v|
  ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update(k => v)
end
CODE


# ====================
# Git
# ====================

file '.gitignore', <<-END
.DS_Store
log/*
*.sqlite3*
public/system/*
tmp/*
index/*
.sass-cache
scratch_directory
TAGS
*.swp
END

# Create an empty schema
rake 'db:migrate'

git :init
git :add => '.'
git :commit => '-a -m "Initial commit"'


# ====================
# Clearance
# ====================

generate :clearance
generate :clearance_features, '--force'

# Add consts clearance needs to the environment
File.open 'config/environments/cucumber.rb', 'a' do |file|
  [ "\n\n",
    "HOST = 'localhost'",
    "DO_NOT_REPLY = 'donotreply@example.com'"
  ].each do |line|
    file.puts line
  end
end

FileUtils.cp('config/database.yml', 'config/database.example.yml')
rake 'db:migrate'

git :add => '.'
git :commit => '-a -m "Added Clearance"'

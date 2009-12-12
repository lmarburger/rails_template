# Fork of Dan Pickett's Enlightened template
# based on Suspenders by Thoughtbot
# influenced by Mike Gunderloy's rails template - http://gist.github.com/145676

# Using bundler: http://github.com/tomafro/dotfiles/blob/master/resources/rails/bundler.rb
inside 'vendor/bundler_gems/gems/bundler' do
  run 'git init'
  run 'git pull --depth 1 git://github.com/wycats/bundler.git'
  run 'rm -rf .git .gitignore'
end

file 'script/bundle', %{
#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'bundler_gems', 'gems', 'bundler', 'lib'))
require 'rubygems'
require 'rubygems/command'
require 'bundler'
require 'bundler/commands/bundle_command'
Gem::Commands::BundleCommand.new.invoke(*ARGV)
}.strip

run 'chmod +x script/bundle'

file 'Gemfile', %{
disable_system_gems

# Not using the standard vendor/gems path to avoid a flood of "Unpacked gem
# cache in vendor/gems has no specification file" errors.
bundle_path 'vendor/bundler_gems'

clear_sources
source 'http://gemcutter.org'
source 'http://gems.github.com'

gem 'rails', '#{ Rails::VERSION::STRING }'
gem 'haml'
gem 'authlogic'
gem 'inherited_resources'
gem 'formtastic'

only :development do
  gem 'sqlite3-ruby'
end

only :test, :cucumber do
  gem 'factory_girl'
  gem 'faker'
end

only :test do
  gem 'shoulda'
  gem 'jnunemaker-matchy', :require_as => 'matchy'
end

only :cucumber do
  gem 'cucumber'
  gem 'webrat'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rr'
end
}.strip

run 'script/bundle'

append_file '/config/preinitializer.rb', %{
require File.expand_path File.join(File.dirname(__FILE__), '..', 'vendor', 'bundler_gems', 'environment')
}

gsub_file 'config/environment.rb', "require File.join(File.dirname(__FILE__), 'boot')", %{
require File.join(File.dirname(__FILE__), 'boot')

# Hijack rails initializer to load the bundler gem environment before loading the rails environment.

Rails::Initializer.module_eval do
  alias load_environment_without_bundler load_environment

  def load_environment
    Bundler.require_env configuration.environment
    load_environment_without_bundler
  end
end
}


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
file 'app/views/home/index.html.haml', '%h1 Welcome to the Internet!'


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

file 'app/views/layouts/application.html.haml', <<-CODE
!!!
%html(xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en")
  %head
    %meta(http-equiv="Content-type" content="text/html; charset=utf-8")
    %title= yield :title

    = stylesheet_link_tag 'main'

  %body(class=body_class)
    = render :partial => 'layouts/flashes'
    = yield
CODE


# ====================
# Tests
# ====================

file 'test/test_helper.rb', <<-CODE
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

# Use Authlogic's test helpers
require 'authlogic/test_case'

require 'rr'
class ActiveSupport::TestCase
  include RR::Adapters::TestUnit
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
*.swo
bin/*
vendor/bundler_gems/*
END

# Create an empty schema
rake 'db:migrate'

git :init
git :add => '.'
git :commit => '-a -m "Initial commit"'


# ====================
# Haml
# ====================

run 'haml --rails .'

git :add => '.'
git :commit => '-a -m "Using Haml"'


# ====================
# Capistrano
# ====================

capify!

git :add => '.'
git :commit => '-a -m "Capified!"'

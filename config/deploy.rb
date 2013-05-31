# General
set :normalize_asset_timestamps, false

# Colorizing
require "capistrano_colors"
Capistrano::Logger.add_color_matcher({:match => /\**.*/, :color => :magenta, :level => 1, :prio => -10})
Capistrano::Logger.add_color_matcher({:match => /\*\**.*/, :color => :red, :level => 0, :prio => -10})

# Directory to put the files into
set :application, "zapfolio"

# Keep the last 5 deploys
set :keep_releases, 5
after "deploy:update", "deploy:cleanup"

# Bundler config
set :bundle_without, [:development, :test, :osx]
set :bundle_flags, "--deployment --quiet"

# Git setup
set :repository, "git@git.aws.zapfol.io:/zapfolio/core"
set :scm, "git"
set :user, "deploy"

set :branch, "master"
set :deploy_via, :remote_cache

# Server config
set :deploy_to, "/var/www/vhosts/zapfolio"
set :use_sudo, false

# Server definition
server "core1.aws.zapfol.io", :web, :app

# Passenger restarting
namespace :deploy do
  task :start do end
  task :stop do end
  task :restart, :except => {:no_release => true} do
    run "touch #{File.join(current_path, "tmp", "restart.txt")}"
  end
end

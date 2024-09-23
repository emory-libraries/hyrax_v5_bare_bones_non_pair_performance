# config valid for current version and patch releases of Capistrano
lock "~> 3.18.1"

# Load environment variables
require 'dotenv'
Dotenv.load('.env.production')

set :application, "hyrax_v5_bare_bones_non_pair_performance"
set :repo_url, "https://github.com/emory-libraries/hyrax_v5_bare_bones_non_pair_performance"
set :deploy_to, '/opt/dlp-selfdeposit'
set :rbenv_ruby, '3.2.2'
set :rbenv_custom_path, '/usr/local/rbenv'
set :rails_env, 'production'
set :assets_prefix, "#{shared_path}/public/assets"
set :migration_role, :app
set :service_unit_name, "sidekiq.service"

SSHKit.config.command_map[:rake] = 'bundle exec rake'

set :branch, ENV['REVISION'] || ENV['BRANCH'] || ENV['BRANCH_NAME'] || 'main'
append :linked_dirs, "log", "public/assets", "tmp/pids", "tmp/cache", "tmp/sockets",
  "tmp/imports", "config/emory/groups", "tmp/csv_uploads", "tmp/csv_uploads_cache"

append :linked_files, ".env.production", "config/secrets.yml"

set :default_env,
    PATH: '$PATH:/usr/local/rbenv/shims/ruby',
    LD_LIBRARY_PATH: '$LD_LIBRARY_PATH:/usr/lib64',
    PASSENGER_INSTANCE_REGISTRY_DIR: '/var/run'

# Default value for local_user is ENV['USER']
set :local_user, -> { `git config user.name`.chomp }

# Restart apache
namespace :deploy do
  after :log_revision, :restart_apache do
    on roles(:ubuntu) do
      execute :sudo, :systemctl, :restart, :httpd
    end
  end
end

namespace :sidekiq do
  task :restart do
    invoke 'sidekiq:stop'
    invoke 'sidekiq:start'
  end

  before 'deploy:finished', 'sidekiq:restart'

  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, :stop, :sidekiq
    end
  end

  task :start do
    on roles(:app) do
      execute :sudo, :systemctl, :start, :sidekiq
    end
  end
end

# Restart apache
namespace :deploy do
  after :restart_apache, :restart_tomcat do
    on roles(:ubuntu) do
      execute :sudo, :systemctl, :restart, :tomcat
    end
  end
end



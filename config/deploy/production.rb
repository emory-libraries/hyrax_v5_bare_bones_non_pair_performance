server ENV['SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :ubuntu]
set :stage, :PRODUCTION

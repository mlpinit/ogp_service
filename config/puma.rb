require 'puma/daemon'

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 4)
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
if ENV['RACK_ENV'] == 'production'
  daemonize true
else
  port ENV['PORT'] || 9292
  daemonize false
end

environment ENV['RACK_ENV'] || 'development'

tag 'ogp_service'

on_worker_boot do
end

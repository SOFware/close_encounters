require "bundler/setup"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

task default: ["db:reset", "db:migrate", "app:environment", :test] # Modify default task

require "reissue/gem"

Reissue::Task.create :reissue do |task|
  task.version_file = "lib/close_encounters/version.rb"
end

require "standard/rake"

require "close_encounters/engine"
load "lib/tasks/close_encounters.rake"

namespace :close_encounters do
  namespace :db do
    desc "Run migrations for CloseEncounters"
    task migrate: :environment do
      ActiveRecord::Migration.migrate(File.expand_path("../../db/migrate", __dir__))
    end
  end
end

Rake::Task["db:migrate"].enhance do
  Rake::Task["close_encounters:db:migrate"].invoke
end

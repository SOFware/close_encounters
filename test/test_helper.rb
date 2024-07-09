# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

if ENV["CI"]
  require "simplecov"
end

require_relative "../test/dummy/config/environment"

ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)

require "rails/test_help"

# Ensure the test schema is up to date
ActiveRecord::Migration.maintain_test_schema!

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

Minitest.backtrace_filter = Minitest::BacktraceFilter.new

class ActiveSupport::TestCase
  # Make tests transactional
  self.use_transactional_tests = true

  # Ensure database is migrated before tests are run
  setup do
    ActiveRecord::Migration.check_all_pending!
  end
end

# Run migrations if they are pending
ActiveRecord::Migration.maintain_test_schema!

puts "Migrations: #{ActiveRecord::Base.connection.migration_context.get_all_versions}"

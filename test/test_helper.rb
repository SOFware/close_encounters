# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "simplecov"
SimpleCov.start "rails" do
  # Use simple formatter in CI for cleaner output
  formatter SimpleCov::Formatter::SimpleFormatter if ENV["CI"] == "true"

  skip "version.rb"
  skip "/test/"
  skip "lib/tasks"

  # Track all files in lib and app
  cover "{app,lib}/**/*.rb"

  # Enable branch coverage
  enable_coverage :branch
end

require_relative "../test/dummy/config/environment"

# Load the gem's library files after SimpleCov is started and Rails is loaded
require "close_encounters"

# Keep deprecation warnings out of test output; tests that assert on them set
# their own behavior locally.
CloseEncounters.deprecator.behavior = :silence

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

ActiveRecord::Migration.maintain_test_schema!
class ActiveSupport::TestCase
  # Make tests transactional
  self.use_transactional_tests = true
end

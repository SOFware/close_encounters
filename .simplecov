SimpleCov.start "rails" do
  # Use simple formatter in CI for cleaner output
  if ENV["CI"] == "true"
    formatter SimpleCov::Formatter::SimpleFormatter
  end

  add_filter "version.rb"
  add_filter "test"
  add_filter "lib/tasks"
end

SimpleCov.start "rails" do
  # Use simple formatter in CI for cleaner output
  if ENV["CI"] == "true"
    formatter SimpleCov::Formatter::SimpleFormatter
  end

  add_filter "version.rb"
  add_filter "/test/"
  add_filter "lib/tasks"

  # Track all files in lib and app
  track_files "{app,lib}/**/*.rb"

  # Enable branch coverage
  enable_coverage :branch
end

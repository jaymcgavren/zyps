require "bundler/setup"
require "zyps"
require "pry"

#Allowed margin of error for be_close.
MARGIN = 0.01

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end

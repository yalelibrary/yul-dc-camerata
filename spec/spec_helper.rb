# frozen_string_literal: true
require "bundler/setup"
require "byebug"
require "camerata"
require "vcr"

Dir[File.join('spec', 'support', '**', '*.rb')].sort.each { |f| load f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Capture
  config.include GithubHygiene
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = true
end

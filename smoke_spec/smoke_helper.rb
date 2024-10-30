# frozen_string_literal: true
require 'byebug'
require 'capybara/rspec'
require 'http'
require 'json'
require 'openssl'
require 'selenium/webdriver'

ENV['RAILS_ENV'] ||= 'test'

Dir["#{File.expand_path(__dir__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_excluding deployed: true if ENV['RAILS_ENV'] == 'development'
  # this only applies to running tests locally - this may not work at all
  # test while on VPN
  # from Jenkins the IP will always be on campus
  config.before(:each) do |example|
    Capybara.server_host = '1.2.3.4' if example.metadata[:off_campus]
  end
end

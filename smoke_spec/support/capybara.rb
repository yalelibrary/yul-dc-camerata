# frozen_string_literal: true
Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :chrome_headless
end

Capybara.register_driver :chrome_headless do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 120
  options = Selenium::WebDriver::Chrome::Options.new(args: %w[disable-gpu no-sandbox whitelisted-ips window-size=1400,1400])
  options.add_argument(
    "--enable-features=NetworkService,NetworkServiceInProcess"
  )

  # capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(accept_insecure_certs: true)
  # options = ::Selenium::WebDriver::Chrome::Options.new
  # options.add_argument('--headless')
  # options.add_argument('--no-sandbox')
  # options.add_argument('--disable-dev-shm-usage')
  # options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client)
end

Capybara.javascript_driver = :chrome_headless

# RSpec.configure do |config|
#   config.before(:each, type: :system) do
#     server_host '1.2.3.4'
#   end
# end

# ***********************************************************
# # frozen_string_literal: true
# Capybara.configure do |config|
#   config.run_server = false
#   config.default_driver = :chrome
# end

# ENV['WEB_HOST'] ||= `hostname -s`.strip

# options = Selenium::WebDriver::Chrome::Options.new(args: %w[disable-gpu no-sandbox whitelisted-ips window-size=1400,1400])
# options.add_argument(
#   "--enable-features=NetworkService,NetworkServiceInProcess"
# )

# Capybara.register_driver :chrome do |app|
#   d = Capybara::Selenium::Driver.new(app,
#                                     browser: :remote,
#                                     options: options)
#   # Fix for capybara vs remote files. Selenium handles this for us
#   d.browser.file_detector = lambda do |args|
#     str = args.first.to_s
#     str if File.exist?(str)
#   end
#   d
# end

# Capybara.server_host = '0.0.0.0'
# Capybara.server_port = 3007
# Capybara.always_include_port = true
# Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
# Capybara.javascript_driver = :chrome

# *******************************************************************

# # frozen_string_literal: true
# # TODO  Webdrivers.cache_time = 3
# Capybara.default_max_wait_time = 8
# Capybara.default_driver = :rack_test

# # Setup chrome headless driver
# # Capybara.server = :puma, { Silent: false }
# ENV['WEB_HOST'] ||= `hostname -s`.strip

# options = Selenium::WebDriver::Chrome::Options.new(args: %w[disable-gpu no-sandbox whitelisted-ips window-size=1400,1400])
# options.add_argument(
#   "--enable-features=NetworkService,NetworkServiceInProcess"
# )

# Capybara.register_driver :chrome do |app|
#   d = Capybara::Selenium::Driver.new(app,
#                                      browser: :remote,
#                                      options: options,
#                                      url: "http://chrome:4444/wd/hub")
#   # Fix for capybara vs remote files. Selenium handles this for us
#   d.browser.file_detector = lambda do |args|
#     str = args.first.to_s
#     str if File.exist?(str)
#   end
#   d
# end
# Capybara.server_host = '0.0.0.0'
# Capybara.server_port = 3007
# Capybara.always_include_port = true
# Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
# Capybara.javascript_driver = :chrome

# # Setup rspec
# RSpec.configure do |config|
#   config.before(:each, type: :system) do
#     driven_by :chrome
#   end

#   config.before(:each, type: :system, js: true) do
#     # rails system specs reset app_host each time so needs to be forced on each test
#     Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
#     driven_by :chrome
#   end
# end

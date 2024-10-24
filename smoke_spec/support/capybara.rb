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
  options.add_argument('--profile-directory=Default')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client)
end

Capybara.javascript_driver = :chrome_headless

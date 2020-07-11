# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |_repo| 'https://github.com/#{repo}.git' }

# Specify your gem's dependencies in camerata.gemspec
gemspec

# TODO: make these development dependencies?
gem 'capybara'
gem 'github_changelog_generator'
gem 'http'
gem 'rake'
gem 'rspec'
gem 'selenium-webdriver'

group :development, :test do
  gem 'bixby'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in camerata.gemspec
gemspec

gem 'github_changelog_generator', '~> 1.16.4'
gem 'rake', '~> 13.0.6'

group :development, :test do
  gem 'bixby', '~> 5.0.2'
  gem 'byebug', '~> 11.1.3', platforms: %i[mri mingw x64_mingw]
  gem 'vcr', '~> 6.1.0'
  gem 'webmock', '~> 3.18.1'
end

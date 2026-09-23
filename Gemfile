# frozen_string_literal: true

source 'https://rubygems.org', cooldown: 30
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in camerata.gemspec
gemspec

gem 'base64', '~> 0.3.0'
gem 'benchmark', '~> 0.5.0'
gem 'github_changelog_generator', '~> 1.16.4'
gem 'ostruct', '~> 0.6.3'
gem 'rake', '~> 13.0.6'
gem 'tsort', '~> 0.2.0'

group :development, :test do
  gem 'bigdecimal', '~> 4.1.3'
  gem 'bixby', '~> 5.0.2'
  gem 'byebug', '~> 11.1.3', platforms: %i[mri mingw x64_mingw]
  gem 'vcr', '~> 6.4.0'
  gem 'webmock', '~> 3.18.1'
end

# frozen_string_literal: true

ruby '3.2.2'

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in camerata.gemspec
gemspec

gem 'github_changelog_generator'
gem 'rake'

group :development, :test do
  gem 'bixby', '~> 5.0.2'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'vcr'
  gem 'webmock'
end

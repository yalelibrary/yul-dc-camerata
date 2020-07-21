# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in camerata.gemspec
gemspec

gem 'github_changelog_generator'
gem 'rake'

group :development, :test do
  gem 'bixby'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

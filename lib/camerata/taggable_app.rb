# frozen_string_literal: true
##
# Tag a release of a microservice, E.g., cam tag blacklight
# This will:
# 1. Check for merged PRs not yet in a release
# 2. Determine whether any of them are features or breaking changes, and increment the version number accordingly
# 3. Auto-generate release notes for the new version
# 4. Tag the release in github with the new version number and the release notes
require 'github_changelog_generator'
require 'octokit'
require 'set'

module Camerata
  class TaggableApp
    attr_reader :github_user, :github_project

    ##
    # Make an instance that's configured for a specific application
    def initialize(app)
      raise "Unknown app name: #{app}" unless Camerata::TaggableApp.known_apps.include?(app)
      raise "CHANGELOG_GITHUB_TOKEN not found" if ENV['CHANGELOG_GITHUB_TOKEN'].nil? || ENV['CHANGELOG_GITHUB_TOKEN'].empty?
      @app = app
      @config = Camerata::TaggableApp.config[app.to_sym]
      @github_user = @config[:github_user]
      @github_project = @config[:github_project]
      @client = ::Octokit::Client.new(access_token: ENV['CHANGELOG_GITHUB_TOKEN'])
    end

    ##
    # Do not make a new release if there are no new PRs
    def release_needed?
      return false if release_prs.empty?
      true
    end

    ##
    # The most recent release
    def last_release
      @last_release ||= @client.releases("#{@github_user}/#{@github_project}")[0]
    end

    ##
    # The name of the most recent release
    def last_version_number
      last_release[:name]
    end

    ##
    # Keep the release PRs in an instance variable so we don't fetch them over
    # and over again
    def release_prs
      @release_prs ||= fetch_release_prs
    end

    ##
    # Fetch the PRs merged since the last release
    # @return [Array] the PRs with timestamps since the last release
    def fetch_release_prs
      last_release_timestamp = last_release[:created_at]
      pull_requests = @client.pulls "#{@github_user}/#{@github_project}", state: 'closed'
      pull_requests.select { |a| a[:merged_at] && a[:merged_at] > last_release_timestamp }
    end

    ##
    # The name of the upcoming release
    def new_version_number
      @new_version_number ||= calculate_new_version_number
    end

    def labels
      @labels ||= union_labels
    end

    ##
    # Get the union set of all of the labels of all the PRs in this release
    def union_labels
      labels = release_prs.map { |a| a[:labels] }.reject!(&:empty?)
      union_labels = Set[]
      labels.each { |a| a.each { |b| union_labels.add(b[:name]) } }
      union_labels
    end

    ##
    # Fetch all the merged PRs since the last release, and determine whether any of
    # them had a "Feature" label. If so, increment the minor part of the version number.
    # If not, increment the patch part of the version number.
    def calculate_new_version_number
      major_release = labels.include?("Major")
      feature_release = labels.include?("Feature")
      major, minor, patch = last_version_number.split(".")

      if major_release
        major = major.delete('v').to_i + 1
        major = "v#{major}"
        minor = 0
        patch = 0
      elsif feature_release
        minor = minor.to_i + 1
        patch = 0
      else
        patch = patch.to_i + 1
      end
      "#{major}.#{minor}.#{patch}"
    end

    def release_notes
      @release_notes ||= generate_release_notes
    end

    ##
    # Generate release notes for all PRs merged since the last release
    def generate_release_notes
      options = ::GitHubChangelogGenerator::Parser.default_options
      options[:user] = @github_user
      options[:project] = @github_project
      options[:since_tag] = last_version_number
      options[:future_release] = new_version_number
      options[:token] = ENV['CHANGELOG_GITHUB_TOKEN']
      options[:enhancement_labels] = ["Feature"]
      options[:bug_labels] = ["Bug", "Bugs", "bug", "bugs"]
      options[:enhancement_prefix] = "**New Features:**"
      options[:bug_prefix] = "**Fixed Bugs:**"
      options[:merge_prefix] = "**Technical Enhancements:**"
      options[:security_labels] = ["dependencies", "security"]
      generator = GitHubChangelogGenerator::Generator.new options
      generator.compound_changelog
    end

    ##
    # In order to release one of our microservices, we need to know the github_user and github_project
    # TODO: Move this to somewhere more obvious in case we want to change this config
    def self.config
      {
        blacklight:
          {
            github_user: 'yalelibrary',
            github_project: 'yul-dc-blacklight'
          },
        management:
        {
          github_user: 'yalelibrary',
          github_project: 'yul-dc-management'
        },
        solr:
        {
          github_user: 'yalelibrary',
          github_project: 'yul-dc-solr'
        },
        postgres:
        {
          github_user: 'yalelibrary',
          github_project: 'yul-dc-postgres'
        },
        iiif_manifest:
        {
          github_user: 'yalelibrary',
          github_project: 'yul-dc-iiif-manifest'
        },
        iiif_imageserver:
        {
          github_user: 'yalelibrary',
          github_project: 'yul-dc-iiif-imageserver'
        }
      }
    end

    ##
    # List the applications we know how to tag
    def self.known_apps
      config.keys.map(&:to_s)
    end

    ##
    # Actually tag a release. Pass the release notes and the new version number.
    def release
      release_options = { name: new_version_number, body: release_notes }
      @client.create_release("#{@github_user}/#{@github_project}", new_version_number, release_options)
    end
  end
end

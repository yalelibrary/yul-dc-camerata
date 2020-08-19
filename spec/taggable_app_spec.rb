# frozen_string_literal: true
##
# A taggable app is microservice that we know how to make a new release for

RSpec.describe Camerata::TaggableApp, type: :github_api do
  it "has a list of apps it knows how to tag" do
    expect(described_class.known_apps).to eq ["blacklight", "management", "solr", "postgres", "iiif_manifest", "iiif_imageserver"]
  end

  context "configuration for a specific app" do
    let(:taggable_app) { described_class.new("blacklight") }
    it "has a github user" do
      expect(taggable_app.github_user).to eq "yalelibrary"
    end
    it "has a github project" do
      expect(taggable_app.github_project).to eq "yul-dc-blacklight"
    end

    context "#release_prs" do
      let(:taggable_app) { described_class.new("blacklight") }
      it "knows how many PRs will be in this release" do
        VCR.use_cassette("release_needed_with_new_PRs") do
          expect(taggable_app.release_prs.size).to eq 4
        end
      end
    end

    context "#release_needed?" do
      let(:taggable_app) { described_class.new("blacklight") }
      it "tags a new release if there are PRs since the last release" do
        VCR.use_cassette("release_needed_with_new_PRs") do
          expect(taggable_app.release_needed?).to eq true
        end
      end
      # We need to record this at some point when management does not have any new PRs
      it "does not tag a new release if there are no PRs since the last release" do
        VCR.use_cassette("release_needed_with_no_new_PRs") do
          expect(taggable_app.release_needed?).to eq false
        end
      end
    end

    context "tagging a release" do
      it "gets the last_version_number" do
        VCR.use_cassette("last_version_number") do
          expect(taggable_app.last_version_number).to eq "v1.11.0"
        end
      end
      context "recording a new version number" do
        it "increments the major version number when there is a PR with a `Major` label" do
          VCR.use_cassette("next_version_number_major") do
            expect(taggable_app.new_version_number).to eq "v2.0.0"
          end
        end
        it "increments the minor version number when there is a PR with a `Feature` label" do
          VCR.use_cassette("next_version_number_minor") do
            expect(taggable_app.new_version_number).to eq "v1.12.0"
          end
        end
        it "increments the patch version number when there are closed PRs for anything else" do
          VCR.use_cassette("next_version_number_patch") do
            expect(taggable_app.new_version_number).to eq "v1.11.1"
          end
        end
      end
      context "#release_notes" do
        it "generates release notes with expected headings" do
          VCR.use_cassette("release_notes", allow_playback_repeats: true) do
            release_notes = taggable_app.release_notes
            expect(release_notes).to match(/New Features:/)
            expect(release_notes).to match(/Fixed Bugs:/)
            expect(release_notes).to match(/Technical Enhancements:/)
          end
        end
      end
    end
  end
end

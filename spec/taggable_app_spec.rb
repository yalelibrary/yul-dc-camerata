# frozen_string_literal: true
##
# A taggable app is microservice that we know how to make a new release for

RSpec.describe Camerata::TaggableApp, type: :github_api do
  before do
    ENV['CHANGELOG_GITHUB_TOKEN'] = 'fake_token' if ENV['CI']
  end

  it "has a list of apps it knows how to tag" do
    expect(described_class.known_apps).to eq ["blacklight", "camerata", "management", "solr", "postgres", "iiif_manifest", "iiif_imageserver"]
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

    context "#union_labels" do
      let(:taggable_app) { described_class.new("blacklight") }
      it "gets the union set of all the labels for this release" do
        VCR.use_cassette("blacklight_with_three_feature_labels") do
          expect(taggable_app.union_labels.size).to eq 1
          expect(taggable_app.union_labels.first).to eq "Feature"
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
        let(:taggable_app) { described_class.new("blacklight") }
        it "generates release notes" do
          expect(taggable_app).to respond_to(:release_notes)
        end
      end
      context "#release" do
        let(:taggable_app) { described_class.new("blacklight") }
        it "has a release method that actually does the release" do
          expect(taggable_app).to respond_to(:release)
        end
      end
      # Camerata has an additional release step, which is to increment the version number in version.rb
      context "#increment_camerata_version" do
        let(:taggable_app) { described_class.new("camerata") }
        it "writes a temporary version file" do
          VCR.use_cassette("make_version_tempfile") do
            tempfile = taggable_app.make_version_tempfile
            expect(tempfile).to be_instance_of(Tempfile)
            tempfile.open
            expect(tempfile.read).to match(taggable_app.new_version_number.delete('v'))
            tempfile.close
          end
        end
      end
    end
  end
end
